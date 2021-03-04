import Foundation

let currentAccountIdentifierKey  = "NYPLCurrentAccountIdentifier"

@objc protocol NYPLCurrentLibraryAccountProvider: NSObjectProtocol {
  var currentAccount: Account? {get}
}

@objc protocol NYPLLibraryAccountsProvider: NYPLCurrentLibraryAccountProvider {
  var NYPLAccountUUID: String {get}
  var currentAccountId: String? {get}
  func account(_ uuid: String) -> Account?
}

/// Manage the library accounts for the app.
/// Initialized with JSON.
@objcMembers final class AccountsManager: NSObject, NYPLLibraryAccountsProvider
{
  static let NYPLAccountUUIDs = [
    "urn:uuid:065c0c11-0d0f-42a3-82e4-277b18786949", //NYPL proper
    "urn:uuid:edef2358-9f6a-4ce6-b64f-9b351ec68ac4", //Brooklyn
    "urn:uuid:56906f26-2c9a-4ae9-bd02-552557720b99"  //Simplified Instant Classics
  ]

  let NYPLAccountUUID = AccountsManager.NYPLAccountUUIDs[0]

  static let shared = AccountsManager()

  // For Objective-C classes
  class func sharedInstance() -> AccountsManager {
    return shared
  }

  private var accountSet: String {
    didSet {
      #if OPENEBOOKS
      // This must be set up otherwise the rest of catalog loading logic gets
      // really confused. It's necessary because OE doesn't provide a way to
      // change the current library.
      setCurrentAccountIdFromSettings()
      #endif
    }
  }

  private var accountSets = [String: [Account]]()
  private var accountSetsWorkQueue = DispatchQueue(label: "org.nypl.labs.SimplyE.AccountsManager.workQueue", attributes: .concurrent)

  var accountsHaveLoaded: Bool {
    var accounts: [Account]?
    accountSetsWorkQueue.sync {
      accounts = accountSets[accountSet]
    }

    if let accounts = accounts {
      return !accounts.isEmpty
    }
    return false
  }

  private var loadingCompletionHandlers = [String: [(Bool) -> ()]]()

  var currentAccount: Account? {
    get {
      guard let uuid = currentAccountId else {
        return nil
      }

      return account(uuid)
    }
    set {
      Log.debug(#file, "Setting currentAccount to <\(newValue?.name ?? "[name N/A]") LibUUID=\(newValue?.uuid ?? "[UUID N/A]")>")
      currentAccountId = newValue?.uuid
      NYPLErrorLogger.setUserID(NYPLUserAccount.sharedAccount().barcode)
      NotificationCenter.default.post(name: NSNotification.Name.NYPLCurrentAccountDidChange,
                                      object: nil)
    }
  }

  private(set) var currentAccountId: String? {
    get {
      return UserDefaults.standard.string(forKey: currentAccountIdentifierKey)
    }
    set {
      Log.debug(#file, "Setting currentAccountId to \(newValue ?? "N/A")>")
      UserDefaults.standard.set(newValue,
                                forKey: currentAccountIdentifierKey)
    }
  }

  #if OPENEBOOKS
  private func setCurrentAccountIdFromSettings() {
    if NYPLSettings.shared.useBetaLibraries {
      currentAccountId = NYPLConfiguration.OpenEBooksUUIDBeta
    } else {
      currentAccountId = NYPLConfiguration.OpenEBooksUUIDProd
    }
  }
  #endif

  private override init() {
    self.accountSet = NYPLSettings.shared.useBetaLibraries ? NYPLConfiguration.betaUrlHash : NYPLConfiguration.prodUrlHash

    super.init()

    #if OPENEBOOKS
    // This must be set up otherwise the rest of catalog loading logic gets
    // really confused. It's necessary because OE doesn't provide a way to
    // change the current library. This is somewhat the closest parallel to
    // setting the Simplified library as default in SimplyE.
    setCurrentAccountIdFromSettings()
    #endif

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(updateAccountSetFromNotification(_:)),
      name: NSNotification.Name.NYPLUseBetaDidChange,
      object: nil
    )

    // It needs to be done asynchronously, so that init returns prior to calling it
    // Otherwise it would try to access itself before intialization is finished
    // Network executor will try to access shared accounts manager, as it needs it to get headers data
    // Think of this async block as you would about viewDidLoad which is
    // triggered after a view is loaded.
    OperationQueue.current?.underlyingQueue?.async {
      // on OE this ends up loading the OPDS2_Catalog_feed.json file stored
      // in the app bundle
      self.loadCatalogs(completion: nil)
    }
  }

  let completionHandlerAccessQueue = DispatchQueue(label: "libraryListCompletionHandlerAccessQueue")

  /// Adds `handler` to the list of completion handlers for `key`.
  ///
  /// - Returns: `true` if loading was happening already.
  private func addLoadingCompletionHandler(key: String,
                                           _ handler: ((Bool) -> ())?) -> Bool {
    var wasEmpty = false
    completionHandlerAccessQueue.sync {
      if loadingCompletionHandlers[key] == nil {
        loadingCompletionHandlers[key] = [(Bool)->()]()
      }
      wasEmpty = loadingCompletionHandlers[key]!.isEmpty
      if let handler = handler {
        loadingCompletionHandlers[key]!.append(handler)
      }
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
   - parameter data: The library catalog list data obtained from fetching either
   `NYPLConfiguration.prodUrl` or `NYPLConfiguration.betaUrl`. This is parsed
   assuming it's in the OPDS2 format.
   - parameter key: The key to enter the `accountSets` dictionary with.
   - parameter completion: Always invoked at the end no matter what, providing
   `true` in case of success and `false` otherwise. No guarantees are being made
   about whether this will be called on the main thread or not.
   */
  private func loadAccountSetsAndAuthDoc(fromCatalogData data: Data,
                                         key: String,
                                         completion: @escaping (Bool) -> ()) {
    do {
      let catalogsFeed = try OPDS2CatalogsFeed.fromData(data)
      let hadAccount = self.currentAccount != nil

      accountSetsWorkQueue.sync(flags: .barrier) {
        accountSets[key] = catalogsFeed.catalogs.map { Account(publication: $0) }
      }

      // note: `currentAccount` computed property feeds off of `accountSets`, so
      // changing the `accountsSets` dictionary will also change `currentAccount`
      Log.debug(#function, "hadAccount=\(hadAccount) currentAccountID=\(currentAccountId ?? "N/A") currentAcct=\(String(describing: currentAccount))")
      if hadAccount != (self.currentAccount != nil) {
        self.currentAccount?.loadAuthenticationDocument(using: NYPLUserAccount.sharedAccount(), completion: { (success) in
          DispatchQueue.main.async {
            var mainFeed = URL(string: self.currentAccount?.catalogUrl ?? "")
            let resolveFn = {
              Log.debug(#function, "mainFeedURL=\(String(describing: mainFeed))")
              NYPLSettings.shared.accountMainFeedURL = mainFeed
              UIApplication.shared.delegate?.window??.tintColor = NYPLConfiguration.mainColor()
              NotificationCenter.default.post(name: NSNotification.Name.NYPLCurrentAccountDidChange, object: nil)
              completion(true)
            }

            // TODO: Test if this is still necessary
            // In past, there was a support for only 1 authenticationmethod, so there was no issue from which of them to pick needsAgeCheck value
            // currently we do support multiple auth methods, and age check is dependant on which of them does user select
            // there is a logic in NYPLUserAcccount authDefinition setter to perform an age check, but it wasn't tested
            // most probably you can delete this check from here
            if self.currentAccount?.details?.needsAgeCheck ?? false {
              NYPLAgeCheck.shared().verifyCurrentAccountAgeRequirement { meetsAgeRequirement in
                DispatchQueue.main.async {
                  mainFeed = self.currentAccount?.details?.defaultAuth?.coppaURL(isOfAge: meetsAgeRequirement)
                  resolveFn()
                }
              }
            } else {
              resolveFn()
            }
          }
        })
      } else {
        // we pass `true` because at this point we know the catalogs loaded
        // successfully
        completion(true)
      }
    } catch (let error) {
      NYPLErrorLogger.logError(error,
                               summary: "Error while parsing catalog feed")
      completion(false)
    }
  }

  /// Loads library catalogs from the network or cache if available.
  ///
  /// After loading the library accounts, the authentication document
  /// for the current library will be loaded in sequence.
  ///
  /// - Parameter completion: Always invoked at the end of the load process.
  /// No guarantees are being made about whether this is called on the main
  /// thread or not.
  func loadCatalogs(completion: ((Bool) -> ())?) {
    Log.debug(#file, "Entering loadCatalog...")
    let targetUrl = NYPLSettings.shared.useBetaLibraries ? NYPLConfiguration.betaUrl : NYPLConfiguration.prodUrl
    let hash = targetUrl.absoluteString.md5().base64EncodedStringUrlSafe()
      .trimmingCharacters(in: ["="])

    let wasAlreadyLoading = addLoadingCompletionHandler(key: hash, completion)
    guard !wasAlreadyLoading else { return }

    Log.debug(#file, "loadCatalog:: GETting \(targetUrl)...")
    NYPLNetworkExecutor.shared.GET(targetUrl) { result in
      switch result {
      case .success(let data, _):
        self.loadAccountSetsAndAuthDoc(fromCatalogData: data, key: hash) { success in
          self.callAndClearLoadingCompletionHandlers(key: hash, success)
          NotificationCenter.default.post(name: NSNotification.Name.NYPLCatalogDidLoad, object: nil)
        }
      case .failure(let error, _):
        NYPLErrorLogger.logError(
          withCode: .libraryListLoadFail,
          summary: "Unable to load libraries list",
          metadata: [
            NSUnderlyingErrorKey: error,
            "targetUrl": targetUrl
        ])
        self.callAndClearLoadingCompletionHandlers(key: hash, false)
      }
    }
  }

  func account(_ uuid: String) -> Account? {
    // get accountSets dictionary first for thread-safety
    var accountSetsCopy = [String: [Account]]()
    var accountSetKey = ""
    accountSetsWorkQueue.sync {
      accountSetsCopy = self.accountSets
      accountSetKey = self.accountSet
    }

    // Check primary account set first
    if let accounts = accountSetsCopy[accountSetKey] {
      if let account = accounts.filter({ $0.uuid == uuid }).first {
        return account
      }
    }

    // Check existing account lists
    for accountEntry in accountSetsCopy {
      if accountEntry.key == accountSetKey {
        continue
      }
      if let account = accountEntry.value.filter({ $0.uuid == uuid }).first {
        return account
      }
    }

    return nil
  }

  func accounts(_ key: String? = nil) -> [Account] {
    var accounts: [Account]? = []

    accountSetsWorkQueue.sync {
      let k = key ?? self.accountSet
      accounts = self.accountSets[k]
    }

    return accounts ?? []
  }

  @objc private func updateAccountSetFromNotification(_ notif: NSNotification) {
    updateAccountSet(completion: nil)
  }

  func updateAccountSet(completion: ((Bool) -> ())?) {
    accountSetsWorkQueue.sync(flags: .barrier) {
      self.accountSet = NYPLSettings.shared.useBetaLibraries ? NYPLConfiguration.betaUrlHash : NYPLConfiguration.prodUrlHash
    }

    if self.accounts().isEmpty {
      loadCatalogs(completion: completion)
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
