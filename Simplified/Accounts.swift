import Foundation

let currentAccountIdentifierKey  = "NYPLCurrentAccountIdentifier"
let userAboveAgeKey              = "NYPLSettingsUserAboveAgeKey"
let userAcceptedEULAKey          = "NYPLSettingsUserAcceptedEULA"
let accountSyncEnabledKey        = "NYPLAccountSyncEnabledKey"


/// Manage the library accounts for the app.
/// Initialized with JSON.
final class AccountsManager: NSObject
{
  static let shared = AccountsManager()
  
  // For Objective-C classes
  @objc class func sharedInstance() -> AccountsManager
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
//    let url = URL(string: "http://www.librarysimplified.org/assets/s9fhw9p8fuewpufje.json")
    let url = Bundle.main.url(forResource: "Accounts", withExtension: "json")
    let data = try? Data(contentsOf: url!)
    do {
      let object = try JSONSerialization.jsonObject(with: data!, options: .allowFragments)
      if let array = object as? [[String: AnyObject]]
      {
        for jsonDict in array
        {
          let account = Account(json: jsonDict)
          
          if (defaults.value(forKey: account.pathComponent!) == nil)
          {
            defaults.set(jsonDict, forKey: account.pathComponent!)
          }
          else
          {
            // update
            var savedDict = defaults.value(forKey: account.pathComponent!) as! [String: AnyObject]
            savedDict["name"] = account.name as AnyObject?
            savedDict["subtitle"] = account.subtitle as AnyObject?
            savedDict["logo"] = account.logo as AnyObject?
            savedDict["needsAuth"] = account.needsAuth as AnyObject?
            savedDict["supportsSimplyESync"] = account.supportsSimplyESync as AnyObject?
            savedDict["supportsBarcodeScanner"] = account.supportsBarcodeScanner as AnyObject?
            savedDict["supportsBarcodeDisplay"] = account.supportsBarcodeDisplay as AnyObject?
            savedDict["supportsCardCreator"] = account.supportsCardCreator as AnyObject?
            savedDict["supportsReservations"] = account.supportsReservations as AnyObject?
            savedDict["supportsHelpCenter"] = account.supportsHelpCenter as AnyObject?
            savedDict["supportEmail"] = account.supportEmail as AnyObject?
            savedDict["catalogUrl"] = account.catalogUrl as AnyObject?
            savedDict["cardCreatorUrl"] = account.cardCreatorUrl as AnyObject?
            savedDict["mainColor"] = account.mainColor as AnyObject?
            
            defaults.set(savedDict, forKey: account.pathComponent!)
          }
          self.accounts.append(account)
        }
      }
    } catch {
      // Handle Error
    }
  }
  
  @objc func account(_ id:Int) -> Account?
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
final class Account:NSObject
{
  let defaults: UserDefaults
  
  let id:Int
  let pathComponent:String?
  let name:String?
  let subtitle:String?
  let logo:String?
  let needsAuth:Bool
  let supportsSimplyESync:Bool
  let supportsBarcodeScanner:Bool
  let supportsBarcodeDisplay:Bool
  let supportsCardCreator:Bool
  let supportsReservations:Bool
  let supportsHelpCenter:Bool
  let catalogUrl:String?
  let cardCreatorUrl:String?
  let supportEmail:String?
  let mainColor:String?
  
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
  var syncIsEnabled:Bool {
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
    
    name = json["name"] as? String
    subtitle = json["subtitle"] as? String
    id = json["id"] as! Int
    pathComponent = json["pathComponent"] as? String
    logo = json["logo"] as? String
    needsAuth = json["needsAuth"] as! Bool
    supportsReservations = json["supportsReservations"] as! Bool
    supportsHelpCenter = json["supportsHelpCenter"] as! Bool
    supportsSimplyESync = json["supportsSimplyESync"] as! Bool
    supportsBarcodeScanner = json["supportsBarcodeScanner"] as! Bool
    supportsBarcodeDisplay = json["supportsBarcodeDisplay"] as! Bool
    supportsCardCreator = json["supportsCardCreator"] as! Bool
    catalogUrl = json["catalogUrl"] as? String
    cardCreatorUrl = json["cardCreatorUrl"] as? String
    supportEmail = json["supportEmail"] as? String
    mainColor = json["mainColor"] as? String
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
    var savedDict = defaults.value(forKey: self.pathComponent!) as! [String: AnyObject]
    savedDict[key] = value
    defaults.set(savedDict, forKey: self.pathComponent!)
  }
  
  fileprivate func getAccountDictionaryKey(_ key: String) -> AnyObject? {
    let savedDict = defaults.value(forKey: self.pathComponent!) as! [String: AnyObject]
    guard let result = savedDict[key] else { return nil }
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
