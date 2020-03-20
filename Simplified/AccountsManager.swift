import Foundation

let currentAccountIdentifierKey  = "NYPLCurrentAccountIdentifier"

private let betaUrl = URL(string: "https://libraryregistry.librarysimplified.org/libraries/qa")!
private let prodUrl = URL(string: "https://libraryregistry.librarysimplified.org/libraries")!
private let betaUrlHash = betaUrl.absoluteString.md5().base64EncodedStringUrlSafe().trimmingCharacters(in: ["="])
private let prodUrlHash = prodUrl.absoluteString.md5().base64EncodedStringUrlSafe().trimmingCharacters(in: ["="])

/**
 Switchboard for fetching data, whether it's from a cache source or fresh from the endpoint.
 - parameter url: Target URL to fetch from.
 - parameter cacheUrl: The target file URL to save the data to.
 - parameter options: Load options to determine the behaviour of this method.
 - parameter completion: Callback invoked when call finishes, providing the
 data or nil if unsuccessful.
 */
func loadDataWithCache(url: URL,
                       cacheUrl: URL,
                       options: AccountsManager.LoadOptions,
                       completion: @escaping (Data?) -> ()) {

  switch NYPLNetworkExecutor.shared.cacheControlForResource(at: url) {
  case .notCached:
    // the resource DOES NOT appear in the executor's cache at all. This means
    // we have to issue a request and this will hit the network.
    break
  case .correct:
    // the resource DOES appear in the executor's cache and it HAS the cache
    // control headers we want. This means that we can issue a request to
    // the executor and that will hit its cache if that's not expired,
    // otherwise it will hit the network.
    break
  case .incorrect:
    // the resource DOES appear in the cache but it's there ephemerally,
    // because it HAS NOT the correct cache control headers. This would be the
    // case of an api response from libraries that did not implement cache
    // control headers. Let's see if it was cached manually on disk.
    let completed = loadDataFromManualCache(cacheUrl: cacheUrl,
                                            options: options,
                                            completion: completion)
    if completed {
      return
    }
  }

  NYPLNetworkExecutor.shared.executeRequest(url) { result in
    switch result {
    case .success(let serverData):
      if !serverData.responseHasCorrectCacheControlHeaders {
        // manual caching, later used in the "incorrect" case above
        try? serverData.data.write(to: cacheUrl)
      }
      completion(serverData.data)
    case .failure(_):
      completion(nil)
    }
  }
}

/**
 Read cached data from our manual cache
 - parameter cacheUrl: The target file URL to save the data to.
 - parameter expiryUnit: The unit of measure for `expiryValue`.
 - parameter expiryValue: How many `expiryUnit`s to keep the cache before expiring it
 - parameter options: Load options to determine the behaviour of this method.
 - parameter completion: Callback invoked if `options` included caching options.
 - returns: `true` if `completion` was invoked, `false` otherwise.
 */
private func loadDataFromManualCache(cacheUrl: URL,
                                     expiryUnit: Calendar.Component = .hour,
                                     expiryValue: Int = 3,
                                     options: AccountsManager.LoadOptions,
                                     completion: @escaping (Data?) -> ()) -> Bool {
  if !options.contains(.noCache) {
    let modified = (try? FileManager.default.attributesOfItem(atPath: cacheUrl.path)[.modificationDate]) as? Date
    if let modified = modified, let expiry = Calendar.current.date(byAdding: expiryUnit, value: expiryValue, to: modified), expiry > Date() {
      if let data = try? Data(contentsOf: cacheUrl) {
        completion(data)
        return true
      }
    }

    if options.contains(.cacheOnly) {
      completion(nil)
      return true
    }
  }

  return false
}

/// Manage the library accounts for the app.
/// Initialized with JSON.
@objcMembers final class AccountsManager: NSObject
{
  struct LoadOptions: OptionSet {
    let rawValue: Int

    // Cache control
    static let preferCache = LoadOptions(rawValue: 1 << 0)
    static let cacheOnly = LoadOptions(rawValue: 1 << 1)
    static let noCache = LoadOptions(rawValue: 1 << 2)
    
    static let online: LoadOptions = []
    static let strict_online: LoadOptions = [.noCache]
    static let offline: LoadOptions = [.preferCache]
    static let strict_offline: LoadOptions = [.preferCache, .cacheOnly]
  }

  static let NYPLAccountUUIDs = [
    "urn:uuid:065c0c11-0d0f-42a3-82e4-277b18786949",
    "urn:uuid:edef2358-9f6a-4ce6-b64f-9b351ec68ac4",
    "urn:uuid:56906f26-2c9a-4ae9-bd02-552557720b99"
  ]
  
  static let shared = AccountsManager()

  // For Objective-C classes
  class func sharedInstance() -> AccountsManager {
    return shared
  }
  
  var accountSet: String
  private var accountSets = [String: [Account]]()
  
  var accountsHaveLoaded: Bool {
    if let accounts = accountSets[accountSet] {
      return !accounts.isEmpty
    }
    return false
  }
  
  var loadingCompletionHandlers = [String: [(Bool) -> ()]]()
  
  var currentAccount: Account? {
    get {
      return account(UserDefaults.standard.string(forKey: currentAccountIdentifierKey) ?? "")
    }
    set {
      UserDefaults.standard.set(newValue?.uuid,
                                forKey: currentAccountIdentifierKey)
      NotificationCenter.default.post(name: NSNotification.Name.NYPLCurrentAccountDidChange, object: nil)
    }
  }
  
  var currentAccountId: String? {
    return UserDefaults.standard.string(forKey: currentAccountIdentifierKey)
  }

  private override init() {
    self.accountSet = NYPLSettings.shared.useBetaLibraries ? betaUrlHash : prodUrlHash
    
    super.init()
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(updateAccountSetFromSettings),
      name: NSNotification.Name.NYPLUseBetaDidChange,
      object: nil
    )
    DispatchQueue.main.async {
      self.loadCatalogs(options: .offline, completion: {_ in })
    }
  }
  
  let completionHandlerAccessQueue = DispatchQueue(label: "libraryListCompletionHandlerAccessQueue")
  
  // Returns whether loading was happening already
  func addLoadingCompletionHandler(key: String, _ handler: @escaping (Bool) -> ()) -> Bool {
    var wasEmpty = false
    completionHandlerAccessQueue.sync {
      if loadingCompletionHandlers[key] == nil {
        loadingCompletionHandlers[key] = [(Bool)->()]()
      }
      wasEmpty = loadingCompletionHandlers[key]!.isEmpty
      loadingCompletionHandlers[key]!.append(handler)
    }
    return !wasEmpty
  }
  
  /**
   Resolves any complation handlers that may have been queued waiting for a registry fetch
   and clears the queue.
   @param key the key for the completion handler list, since there are multiple
   @param success success indicator to pass on to each handler
   */
  private func callAndClearLoadingCompletionHandlers(key: String, _ success: Bool) {
    var handlers = [(Bool) -> ()]()
    completionHandlerAccessQueue.sync {
      if let h = loadingCompletionHandlers[key] {
        handlers = h
        loadingCompletionHandlers[key] = []
      }
    }
    for handler in handlers {
      handler(success)
    }
  }
  
  private func libraryListCacheUrl(name: String) -> URL {
    let applicationSupportUrl = try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    let url = applicationSupportUrl.appendingPathComponent("library_list_\(name).json")
    return url
  }

  /**
   Take the library list data (either from cache or the internet), load it into
   self.accounts, and load the auth document for the current account if
   necessary.
   - parameter data: The library list data.
   - parameter options: Load options to determine the behaviour of this method.
   - parameter key: ???
   - parameter completion: Always invoked at the end no matter what, providing
   `true` in case of success and `false` otherwise.
   */
  private func loadCatalogs(data: Data, options: LoadOptions, key: String, completion: @escaping (Bool) -> ()) {
    do {
      let catalogsFeed = try OPDS2CatalogsFeed.fromData(data)
      let hadAccount = self.currentAccount != nil
      self.accountSets[key] = catalogsFeed.catalogs.map { Account(publication: $0) }

      // note: `currentAccount` computed property feeds off of `accountSets`, so
      // changing the `accountsSets` dictionary will also change `currentAccount`
      if hadAccount != (self.currentAccount != nil) {
        self.currentAccount?.loadAuthenticationDocument(completion: { (success) in
          if !success {
            Log.error(#file, "Failed to load authentication document for current account; a bunch of things likely won't work")
          }
          DispatchQueue.main.async {
            var mainFeed = URL(string: self.currentAccount?.catalogUrl ?? "")
            let resolveFn = {
              NYPLSettings.shared.accountMainFeedURL = mainFeed
              UIApplication.shared.delegate?.window??.tintColor = NYPLConfiguration.mainColor()
              NotificationCenter.default.post(name: NSNotification.Name.NYPLCurrentAccountDidChange, object: nil)
              completion(true)
            }
            if self.currentAccount?.details?.needsAgeCheck ?? false {
              AgeCheck.shared().verifyCurrentAccountAgeRequirement { meetsAgeRequirement in
                DispatchQueue.main.async {
                  mainFeed = meetsAgeRequirement ? self.currentAccount?.details?.coppaOverUrl : self.currentAccount?.details?.coppaUnderUrl
                  resolveFn()
                }
              }
            } else {
              resolveFn()
            }
          }
        })
      } else {
        completion(true)
      }
    } catch (let error) {
      Log.error(#file, "Couldn't load catalogs. Error: \(error.localizedDescription)")
      completion(false)
    }
  }
  
  func loadCatalogs(options: LoadOptions, completion: @escaping (Bool) -> ()) {
    let targetUrl = NYPLSettings.shared.useBetaLibraries ? betaUrl : prodUrl
    let hash = targetUrl.absoluteString.md5().base64EncodedStringUrlSafe().trimmingCharacters(in: ["="])
    
    let wasAlreadyLoading = addLoadingCompletionHandler(key: hash, completion)
    if wasAlreadyLoading {
      return
    }
    
    let cacheUrl = libraryListCacheUrl(name: hash)
    
    loadDataWithCache(url: targetUrl,
                      cacheUrl: cacheUrl,
                      options: options) { data in
      if let data = data {
        self.loadCatalogs(data: data, options: options, key: hash) { (success) in
          self.callAndClearLoadingCompletionHandlers(key: hash, success)
          NotificationCenter.default.post(name: NSNotification.Name.NYPLCatalogDidLoad, object: nil)
        }
      } else {
        self.callAndClearLoadingCompletionHandlers(key: hash, false)
      }
    }
  }
  
  func account(_ uuid:String) -> Account? {
    // Check primary account set first
    if let accounts = self.accountSets[self.accountSet] {
      if let account = accounts.filter({ $0.uuid == uuid }).first {
        return account
      }
    }
    // Check existing account lists
    for accountEntry in self.accountSets {
      if accountEntry.key == self.accountSet {
        continue
      }
      if let account = accountEntry.value.filter({ $0.uuid == uuid }).first {
        return account
      }
    }
    return nil
  }
  
  func accounts(_ key: String? = nil) -> [Account] {
    let k = key != nil ? key! : self.accountSet
    return self.accountSets[k] ?? []
  }
  
  func updateAccountSetFromSettings() {
    self.accountSet = NYPLSettings.shared.useBetaLibraries ? betaUrlHash : prodUrlHash
    if self.accounts().isEmpty {
      loadCatalogs(options: .offline, completion: {_ in })
    }
  }

  func clearCache() {
    NYPLNetworkExecutor.shared.clearCache()
    do {
      let applicationSupportUrl = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
      let appSupportDirContents = try FileManager.default.contentsOfDirectory(at: applicationSupportUrl, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants])
      let libraryListCaches = appSupportDirContents.filter { (url) -> Bool in
        return url.lastPathComponent.starts(with: "library_list_") && url.pathExtension == "json"
      }
      let authDocCaches = appSupportDirContents.filter { (url) -> Bool in
        return url.lastPathComponent.starts(with: "authentication_document_") && url.pathExtension == "json"
      }
      for cache in libraryListCaches {
        do {
          try FileManager.default.removeItem(at: cache)
        } catch {
          Log.error("ClearCache", "Unable to clear cache for: \(cache)")
        }
      }
      for cache in authDocCaches {
        do {
          try FileManager.default.removeItem(at: cache)
        } catch {
          Log.error("ClearCache", "Unable to clear cache for: \(cache)")
        }
      }
    } catch {
      Log.error("ClearCache", "Unable to clear cache")
    }
  }
}
