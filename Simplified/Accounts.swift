import Foundation

let currentAccountIdentifierKey  = "NYPLCurrentAccountIdentifier"
let userAboveAgeKey              = "NYPLSettingsUserAboveAgeKey"
let userAcceptedEULAKey          = "NYPLSettingsUserAcceptedEULA"
let accountSyncEnabledKey        = "NYPLAccountSyncEnabledKey"


/// Manage the library accounts for the app.
/// Initialized with JSON.
@objcMembers final class AccountsManager: NSObject
{
  static let shared = AccountsManager()
  
  // For Objective-C classes
  class func sharedInstance() -> AccountsManager
  {
    return AccountsManager.shared
  }
  
  let defaults: UserDefaults
  var accounts = [Account]()
  
  var currentAccount: Account? {
    get {
      return account(defaults.integer(forKey: currentAccountIdentifierKey))
    }
    set {
      defaults.set(newValue?.id, forKey: currentAccountIdentifierKey)
      NotificationCenter.default.post(name: NSNotification.Name.NYPLCurrentAccountDidChange, object: nil)
    }
  }

  fileprivate override init()
  {
    self.defaults = UserDefaults.standard
    
    super.init()
    
    loadCatalogs(preferringCache: true, completion: {_ in })
  }
  
  func loadCatalogs(preferringCache: Bool, completion: @escaping (Bool) -> ()) {
    let isBeta = NYPLConfiguration.releaseStageIsBeta() && !UserDefaults.standard.bool(forKey: "prod_only")
    let betaUrl = URL(string: "http://libraryregistry.librarysimplified.org/libraries")
    let prodUrl = URL(string: "http://libraryregistry.librarysimplified.org/libraries") // TODO: This needs to be replaced once there's a new endpoint
    guard let url = isBeta ? betaUrl : prodUrl else {
      return;
    }
    
    let handleData = { (data: Data) in
      do {
        let catalogsFeed = try OPDS2CatalogsFeed.fromData(data)
        var id = 0
        let hadAccount = self.currentAccount != nil
        self.accounts = catalogsFeed.catalogs.map {
          let account = Account(publication: $0, id: id)
          id += 1
          return account
        }
        if hadAccount != (self.currentAccount != nil) {
          self.currentAccount?.loadAuthenticationDocument(preferringCache: preferringCache, completion: { (success) in
            if !success {
              Log.error(#file, "Failed to load authentication document for current account; a bunch of things likely won't work")
            }
            DispatchQueue.main.async {
              NYPLSettings.shared()?.accountMainFeedURL = URL(string: self.currentAccount?.catalogUrl ?? "")
              UIApplication.shared.delegate?.window??.tintColor = NYPLConfiguration.mainColor()
              NotificationCenter.default.post(name: NSNotification.Name.NYPLCurrentAccountDidChange, object: nil)
              completion(true)
            }
          })
        }
      } catch (let error) {
        Log.error(#file, "Couldn't load catalogs. Error: \(error.localizedDescription)")
        completion(false)
      }
    }
    
    let cachesUrl = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let libraryListCacheUrl = cachesUrl.appendingPathComponent("library_list_\(isBeta ? "beta" : "prod").json")
    let modified = (try? FileManager.default.attributesOfItem(atPath: libraryListCacheUrl.path)[.modificationDate]) as? Date
    if let modified = modified, let expiry = Calendar.current.date(byAdding: .day, value: 1, to: modified), expiry > Date() || preferringCache {
      if let data = try? Data(contentsOf: libraryListCacheUrl) {
        handleData(data)
        return
      }
    }
    
    // Load data from the internet if either the cache wasn't recent enough (or preferred), or somehow failed to load
    var request = URLRequest.init(url: url,
                                  cachePolicy: .reloadIgnoringLocalCacheData,
                                  timeoutInterval: 60)
    request.httpMethod = "GET"
    
    let dataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
      guard let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        Log.error(#file, "Couldn't load catalogs. Error: \(error?.localizedDescription ?? "")")
        completion(false)
        return
      }
      try? data.write(to: libraryListCacheUrl)
      handleData(data)
    }
    dataTask.resume()
  }
  
  func account(_ id:Int) -> Account?
  {
    return self.accounts.filter{ $0.id == id }.first
  }
  
  func changeCurrentAccount(identifier id: Int)
  {
    if let account = account(id) {
      self.currentAccount = account
    }
  }
}

// Extra data that gets loaded from an OPDS2AuthenticationDocument,
@objcMembers final class AccountDetails: NSObject {
  let defaults:UserDefaults
  let needsAuth:Bool
  let pathComponent:String
  let authPasscodeLength:UInt
  let patronIDKeyboard:LoginKeyboard
  let pinKeyboard:LoginKeyboard
  let supportsSimplyESync:Bool
  let supportsBarcodeScanner:Bool
  let supportsBarcodeDisplay:Bool
  let supportsCardCreator:Bool
  let supportsReservations:Bool
  let mainColor:String?
  let userProfileUrl:String?
  let cardCreatorUrl:String?
  
  fileprivate var urlAnnotations:URL?
  fileprivate var urlAcknowledgements:URL?
  fileprivate var urlContentLicenses:URL?
  fileprivate var urlEULA:URL?
  fileprivate var urlPrivacyPolicy:URL?
  
  var eulaIsAccepted:Bool {
    get {
      guard let result = getAccountDictionaryKey(userAcceptedEULAKey) else { return false }
      return result as! Bool
    }
    set {
      setAccountDictionaryKey(userAcceptedEULAKey, toValue: newValue as AnyObject)
    }
  }
  var syncPermissionGranted:Bool {
    get {
      guard let result = getAccountDictionaryKey(accountSyncEnabledKey) else { return false }
      return result as! Bool
    }
    set {
      setAccountDictionaryKey(accountSyncEnabledKey, toValue: newValue as AnyObject)
    }
  }
  var userAboveAgeLimit:Bool {
    get {
      guard let result = getAccountDictionaryKey(userAboveAgeKey) else { return false }
      return result as! Bool
    }
    set {
      setAccountDictionaryKey(userAboveAgeKey, toValue: newValue as AnyObject)
    }
  }
  
  init(authenticationDocument: OPDS2AuthenticationDocument, uuid: String) {
    defaults = .standard
    needsAuth = !authenticationDocument.authentication.isEmpty
    pathComponent = uuid
    
    supportsReservations = authenticationDocument.features.disabled?.contains("https://librarysimplified.org/rel/policy/reservations") != true
    userProfileUrl = authenticationDocument.links.first(where: { $0.rel == "http://librarysimplified.org/terms/rel/user-profile" })?.href
    supportsSimplyESync = userProfileUrl != nil
    
    mainColor = authenticationDocument.colorScheme
    
    // TODO: Should we preference different authentication schemes, rather than just getting the first?
    let auth = authenticationDocument.authentication.first
    patronIDKeyboard = LoginKeyboard(auth?.inputs.login.keyboard) ?? .standard
    pinKeyboard = LoginKeyboard(auth?.inputs.password.keyboard) ?? .standard
    // Default to 100; a value of 0 means "don't show this UI element at all", not "unlimited characters"
    authPasscodeLength = auth?.inputs.password.maximumLength ?? 99
    // In the future there could be more formats, but we only know how to support this one
    supportsBarcodeScanner = auth?.inputs.login.barcodeFormat == "Codabar"
    supportsBarcodeDisplay = supportsBarcodeScanner
    
    let registerUrl = authenticationDocument.links.first(where: { $0.rel == "register" })?.href
    if let url = registerUrl, url.hasPrefix("nypl.card-creator:") == true {
      supportsCardCreator = true
      cardCreatorUrl = String(url.dropFirst("nypl.card-creator:".count))
    } else {
      supportsCardCreator = false
      cardCreatorUrl = registerUrl
    }
    
    super.init()
    
    if let urlString = authenticationDocument.links.first(where: { $0.rel == "privacy-policy" })?.href,
      let url = URL(string: urlString) {
      setURL(url, forLicense: .privacyPolicy)
    }
    
    if let urlString = authenticationDocument.links.first(where: { $0.rel == "terms-of-service" })?.href,
      let url = URL(string: urlString) {
      setURL(url, forLicense: .eula)
    }
    
    if let urlString = authenticationDocument.links.first(where: { $0.rel == "license" })?.href,
      let url = URL(string: urlString) {
      setURL(url, forLicense: .contentLicenses)
    }
    
    if let urlString = authenticationDocument.links.first(where: { $0.rel == "copyright" })?.href,
      let url = URL(string: urlString) {
      setURL(url, forLicense: .acknowledgements)
    }
  }
  
  func setURL(_ URL: URL, forLicense urlType: URLType) -> Void {
    switch urlType {
    case .acknowledgements:
      urlAcknowledgements = URL
      setAccountDictionaryKey("urlAcknowledgements", toValue: URL.absoluteString as AnyObject)
    case .contentLicenses:
      urlContentLicenses = URL
      setAccountDictionaryKey("urlContentLicenses", toValue: URL.absoluteString as AnyObject)
    case .eula:
      urlEULA = URL
      setAccountDictionaryKey("urlEULA", toValue: URL.absoluteString as AnyObject)
    case .privacyPolicy:
      urlPrivacyPolicy = URL
      setAccountDictionaryKey("urlPrivacyPolicy", toValue: URL.absoluteString as AnyObject)
    case .annotations:
      urlAnnotations = URL
      setAccountDictionaryKey("urlAnnotations", toValue: URL.absoluteString as AnyObject)
    }
  }
  
  func getLicenseURL(_ type: URLType) -> URL? {
    switch type {
    case .acknowledgements:
      if let url = urlAcknowledgements {
        return url
      } else {
        guard let urlString = getAccountDictionaryKey("urlAcknowledgements") as? String else { return nil }
        guard let result = URL(string: urlString) else { return nil }
        return result
      }
    case .contentLicenses:
      if let url = urlContentLicenses {
        return url
      } else {
        guard let urlString = getAccountDictionaryKey("urlContentLicenses") as? String else { return nil }
        guard let result = URL(string: urlString) else { return nil }
        return result
      }
    case .eula:
      if let url = urlEULA {
        return url
      } else {
        guard let urlString = getAccountDictionaryKey("urlEULA") as? String else { return nil }
        guard let result = URL(string: urlString) else { return nil }
        return result
      }
    case .privacyPolicy:
      if let url = urlPrivacyPolicy {
        return url
      } else {
        guard let urlString = getAccountDictionaryKey("urlPrivacyPolicy") as? String else { return nil }
        guard let result = URL(string: urlString) else { return nil }
        return result
      }
    case .annotations:
      if let url = urlAnnotations {
        return url
      } else {
        guard let urlString = getAccountDictionaryKey("urlAnnotations") as? String else { return nil }
        guard let result = URL(string: urlString) else { return nil }
        return result
      }
    }
  }
  
  fileprivate func setAccountDictionaryKey(_ key: String, toValue value: AnyObject) {
    if var savedDict = defaults.value(forKey: self.pathComponent) as? [String: AnyObject] {
      savedDict[key] = value
      defaults.set(savedDict, forKey: self.pathComponent)
    } else {
      defaults.set([key:value], forKey: self.pathComponent)
    }
  }
  
  fileprivate func getAccountDictionaryKey(_ key: String) -> AnyObject? {
    let savedDict = defaults.value(forKey: self.pathComponent) as? [String: AnyObject]
    guard let result = savedDict?[key] else { return nil }
    return result
  }
}

/// Object representing one library account in the app. Patrons may
/// choose to sign up for multiple Accounts.
@objcMembers final class Account: NSObject
{
  let logo:UIImage
  let id:Int
  let uuid:String
  let name:String
  let subtitle:String?
  let supportEmail:String?
  let catalogUrl:String?
  var details:AccountDetails?
  
  let authenticationDocumentUrl:String?
  var authenticationDocument:OPDS2AuthenticationDocument? {
    didSet {
      guard let authenticationDocument = authenticationDocument else {
        return
      }
      details = AccountDetails(authenticationDocument: authenticationDocument, uuid: uuid)
    }
  }
  
  init(publication: OPDS2Publication, id: Int) {
    
    name = publication.metadata.title
    subtitle = publication.metadata.description
    self.id = id
    uuid = publication.metadata.id
    
    catalogUrl = publication.links.first(where: { $0.rel == "http://opds-spec.org/catalog" })?.href
    supportEmail = publication.links.first(where: { $0.rel == "help" })?.href.replacingOccurrences(of: "mailto:", with: "")
    
    authenticationDocumentUrl = publication.links.first(where: { $0.type == "application/vnd.opds.authentication.v1.0+json" })?.href
    
    let logoString = publication.images?.first(where: { $0.rel == "http://opds-spec.org/image/thumbnail" })?.href
    if let modString = logoString?.replacingOccurrences(of: "data:image/png;base64,", with: ""),
      let logoData = Data.init(base64Encoded: modString),
      let logoImage = UIImage(data: logoData) {
      logo = logoImage
    } else {
      logo = UIImage.init(named: "LibraryLogoMagic")!
    }
  }
  
  func loadAuthenticationDocument(preferringCache: Bool, completion: @escaping (Bool) -> ()) {
    guard let urlString = authenticationDocumentUrl, let url = URL(string: urlString) else {
      Log.error(#file, "Invalid or missing authentication document URL")
      completion(false)
      return
    }
    
    let handleData = { (data: Data) in
      do {
        self.authenticationDocument = try OPDS2AuthenticationDocument.fromData(data)
        completion(true)
        
      } catch (let error) {
        Log.error(#file, "Failed to load authentication document for library: \(error.localizedDescription)")
        completion(false)
      }
    }
    
    let cachesUrl = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let nonColonUuid = uuid.replacingOccurrences(of: ":", with: "_")
    let authDocumentCacheUrl = cachesUrl.appendingPathComponent("authentication_document_\(nonColonUuid).json")
    let modified = (try? FileManager.default.attributesOfItem(atPath: authDocumentCacheUrl.path)[.modificationDate]) as? Date
    if let modified = modified, let expiry = Calendar.current.date(byAdding: .day, value: 1, to: modified), expiry > Date() || preferringCache {
      if let data = try? Data(contentsOf: authDocumentCacheUrl) {
        handleData(data)
        return
      }
    }
    
    var request = URLRequest.init(url: url,
                                  cachePolicy: .useProtocolCachePolicy,
                                  timeoutInterval: 60)
    request.httpMethod = "GET"
    
    let dataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
      guard let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        Log.error(#file, "Failed to load authentication document for library: \(error?.localizedDescription ?? "")")
        completion(false)
        return
      }
      
      handleData(data)
    }
    dataTask.resume()
  }
}

@objc enum URLType: Int {
  case acknowledgements
  case contentLicenses
  case eula
  case privacyPolicy
  case annotations
}

@objc enum LoginKeyboard: Int {
  case standard
  case email
  case numeric
  case none

  init?(_ stringValue: String?) {
    if stringValue == "Default" {
      self = .standard
    } else if stringValue == "Email address" {
      self = .email
    } else if stringValue == "Number pad" {
      self = .numeric
    } else if stringValue == "No input" {
      self = .none
    } else {
      Log.error(#file, "Invalid init parameter for PatronPINKeyboard: \(stringValue ?? "nil")")
      return nil
    }
  }
}
