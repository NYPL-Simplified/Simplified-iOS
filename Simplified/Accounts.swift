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
      return account(defaults.integer(forKey: currentAccountIdentifierKey))!
    }
    set {
      defaults.set(currentAccount.id, forKey: currentAccountIdentifierKey)
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
            savedDict["supportsReservations"] = account.supportsReservations as AnyObject?
            savedDict["catalogUrl"] = account.catalogUrl as AnyObject?
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
  let supportsReservations:Bool
  let catalogUrl:String?
  let mainColor:String?
  
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
    catalogUrl = json["catalogUrl"] as? String
    mainColor = json["mainColor"] as? String
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


