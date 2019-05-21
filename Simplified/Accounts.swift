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
  var currentAccount: Account {
    get {
      if account(defaults.integer(forKey: currentAccountIdentifierKey)) == nil
      {
        defaults.set(0, forKey: currentAccountIdentifierKey)
      }
      return account(defaults.integer(forKey: currentAccountIdentifierKey))!
    }
    set {
      defaults.set(newValue.id, forKey: currentAccountIdentifierKey)
      NotificationCenter.default.post(name: NSNotification.Name(rawValue: NYPLCurrentAccountDidChangeNotification), object: nil)
    }
  }

  fileprivate override init()
  {
    self.defaults = UserDefaults.standard
    let url = Bundle.main.url(forResource: "Accounts", withExtension: "json")
    let data = try? Data(contentsOf: url!)
    do {
      let object = try JSONSerialization.jsonObject(with: data!, options: .allowFragments)
      if let array = object as? [[String: AnyObject]]
      {
        for jsonDict in array
        {
          let account = Account(json: jsonDict)
          if (account.inProduction ||
            (NYPLConfiguration.releaseStageIsBeta() && !UserDefaults.standard.bool(forKey: "prod_only"))) {
            self.accounts.append(account)
          }
        }
      }
    } catch {
      Log.error(#file, "Accounts.json was invalid. Error: \(error.localizedDescription)")
    }
    
    super.init()
    loadCatalogs(completion: {_ in })
  }
  
  func loadCatalogs(completion: @escaping (Bool) -> ()) {
    guard let url = URL(string: "http://libraryregistry.librarysimplified.org/libraries") else {
      return;
    }
    DispatchQueue.global().async {
      do {
        let data = try Data(contentsOf: url)
        let catalogsFeed = try OPDS2CatalogsFeed.fromData(data)
        var id = 0
        self.accounts = catalogsFeed.catalogs.map {
          let account = Account(publication: $0, id: id)
          id += 1
          return account
        }
        completion(true)
      } catch (let error) {
        Log.error(#file, "Couldn't load catalogs. Error: \(error.localizedDescription)")
        completion(false)
      }
    }
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

/// Object representing one library account in the app. Patrons may
/// choose to sign up for multiple Accounts.
@objcMembers final class Account:NSObject
{
  let defaults:UserDefaults
  let logo:UIImage
  let id:Int
  let uuid:String?
  let pathComponent:String
  let name:String
  let subtitle:String?
  var needsAuth:Bool
  var authPasscodeLength:UInt
  var patronIDKeyboard:LoginKeyboard
  var pinKeyboard:LoginKeyboard
  var supportsSimplyESync:Bool
  var supportsBarcodeScanner:Bool
  var supportsBarcodeDisplay:Bool
  var supportsCardCreator:Bool
  var supportsReservations:Bool
  let catalogUrl:String?
  var cardCreatorUrl:String?
  let supportEmail:String?
  var mainColor:String?
  let inProduction:Bool
  var userProfileUrl:String?
  
  let authenticationDocumentUrl:String?
  var authenticationDocument:OPDS2AuthenticationDocument? {
    didSet {
      guard let authenticationDocument = authenticationDocument else {
        return
      }
      needsAuth = !authenticationDocument.authentication.isEmpty
      
      supportsReservations = authenticationDocument.features.disabled?.contains("https://librarysimplified.org/rel/policy/reservations") != true
      userProfileUrl = authenticationDocument.links.first(where: { $0.rel == "http://librarysimplified.org/terms/rel/user-profile" })?.href
      supportsSimplyESync = userProfileUrl != nil
      cardCreatorUrl = authenticationDocument.links.first(where: { $0.rel == "register" })?.href
      supportsCardCreator = false // TODO: Set to true based on a custom URL scheme
      
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
      
      mainColor = authenticationDocument.colorScheme
      
      supportsBarcodeScanner = false
      supportsBarcodeDisplay = false
      // TODO: Should we preference different authentication details, rather than just getting the first?
      if let auth = authenticationDocument.authentication.first {
        patronIDKeyboard = LoginKeyboard(auth.inputs.login.keyboard) ?? .standard
        pinKeyboard = LoginKeyboard(auth.inputs.password.keyboard) ?? .standard
        // Default to 100; a value of 0 means "don't show this UI element at all", not "unlimited characters"
        authPasscodeLength = auth.inputs.password.maximumLength ?? 99
        // In the future there could be more formats, but we only know how to support this one
        supportsBarcodeScanner = auth.inputs.login.barcodeFormat == "Codabar"
        supportsBarcodeDisplay = supportsBarcodeScanner
      }
    }
  }
  
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
  
  init(json: [String: AnyObject])
  {
    defaults = UserDefaults.standard
    
    name = json["name"] as! String
    subtitle = json["subtitle"] as? String
    id = json["id_numeric"] as! Int
    uuid = json["id_uuid"] as? String
    pathComponent = "\(id)"
    needsAuth = json["needsAuth"] as! Bool
    supportsReservations = json["supportsReservations"] as! Bool
    supportsSimplyESync = json["supportsSimplyESync"] as! Bool
    supportsBarcodeScanner = json["supportsBarcodeScanner"] as! Bool
    supportsBarcodeDisplay = json["supportsBarcodeDisplay"] as! Bool
    supportsCardCreator = json["supportsCardCreator"] as! Bool
    catalogUrl = json["catalogUrl"] as? String
    cardCreatorUrl = json["cardCreatorUrl"] as? String
    supportEmail = json["supportEmail"] as? String
    mainColor = json["mainColor"] as? String
    patronIDKeyboard = LoginKeyboard(json["loginKeyboard"] as? String) ?? .standard
    pinKeyboard = LoginKeyboard(json["pinKeyboard"] as? String) ?? .standard
    inProduction = json["inProduction"] as! Bool

    let logoString = json["logo"] as? String
    if let modString = logoString?.replacingOccurrences(of: "data:image/png;base64,", with: ""),
      let logoData = Data.init(base64Encoded: modString),
      let logoImage = UIImage(data: logoData) {
      logo = logoImage
    } else {
      logo = UIImage.init(named: "LibraryLogoMagic")!
    }

    if let length = json["authPasscodeLength"] as? UInt {
      authPasscodeLength = length
    } else {
      authPasscodeLength = 0
    }
    
    authenticationDocumentUrl = nil
  }
  
  init(publication: OPDS2Publication, id: Int) {
    defaults = UserDefaults.standard
    
    name = publication.metadata.title
    subtitle = publication.metadata.description
    self.id = id
    uuid = publication.metadata.id
    pathComponent = publication.metadata.id
    
    // These are all in the authentication document
    needsAuth = true
    supportsReservations = false
    supportsSimplyESync = false
    supportsBarcodeScanner = false
    supportsBarcodeDisplay = false
    supportsCardCreator = false
    cardCreatorUrl = nil
    mainColor = nil
    patronIDKeyboard = .standard
    pinKeyboard = .standard
    authPasscodeLength = 99
    
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
    
    inProduction = true
  }
  
  func loadAuthenticationDocument(completion: @escaping (Bool) -> ()) {
    guard let urlString = authenticationDocumentUrl, let url = URL(string: urlString) else {
      completion(false)
      return
    }
    DispatchQueue.global().async { [weak self] in
      do {
        let data = try Data(contentsOf: url)
        self?.authenticationDocument = try OPDS2AuthenticationDocument.fromData(data)
        completion(true)
      } catch (let error) {
        Log.error(#file, "Failed to load authentication document for library: \(error.localizedDescription)")
        completion(false)
      }
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
