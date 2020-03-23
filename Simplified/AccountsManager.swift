import Foundation

let currentAccountIdentifierKey  = "NYPLCurrentAccountIdentifier"

private let betaUrl = URL(string: "https://libraryregistry.librarysimplified.org/libraries/qa")!
private let prodUrl = URL(string: "https://libraryregistry.librarysimplified.org/libraries")!
private let betaUrlHash = betaUrl.absoluteString.md5().base64EncodedStringUrlSafe().trimmingCharacters(in: ["="])
private let prodUrlHash = prodUrl.absoluteString.md5().base64EncodedStringUrlSafe().trimmingCharacters(in: ["="])

/**
 Switchboard for fetching data, whether it's from a cache source or fresh from the endpoint.
 - parameter url: Target URL to fetch from.
 - parameter completion: Callback invoked when call finishes, providing the
 data or nil if unsuccessful.
 */
func loadDataWithCache(url: URL,
                       completion: @escaping (Data?) -> ()) {

  NYPLNetworkExecutor.shared.GET(url) { result in
    DispatchQueue.main.async {
      switch result {
      case .success(let serverData):
        completion(serverData)
      case .failure(_):
        completion(nil)
      }
    }
  }
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

    self.loadCatalogs(completion: {_ in })
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

  /**
   Take the library list data (either from cache or the internet), load it into
   self.accounts, and load the auth document for the current account if
   necessary.
   - parameter data: The library list data.
   - parameter key: ???
   - parameter completion: Always invoked at the end no matter what, providing
   `true` in case of success and `false` otherwise.
   */
  private func loadCatalogs(data: Data, key: String, completion: @escaping (Bool) -> ()) {
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
  
  func loadCatalogs(completion: @escaping (Bool) -> ()) {
    let targetUrl = NYPLSettings.shared.useBetaLibraries ? betaUrl : prodUrl
    let hash = targetUrl.absoluteString.md5().base64EncodedStringUrlSafe()
      .trimmingCharacters(in: ["="])
    
    let wasAlreadyLoading = addLoadingCompletionHandler(key: hash, completion)
    if wasAlreadyLoading {
      return
    }

    loadDataWithCache(url: targetUrl) { data in
      if let data = data {
        self.loadCatalogs(data: data, key: hash) { (success) in
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
      loadCatalogs(completion: {_ in })
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
