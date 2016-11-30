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
  
  let defaults: NSUserDefaults
  var accounts = [Account]()
  var currentAccount: Account {
    get {
      return account(defaults.integerForKey(currentAccountIdentifierKey))!
    }
    set {
      defaults.setInteger(currentAccount.id, forKey: currentAccountIdentifierKey)
    }
  }

  private override init()
  {
    self.defaults = NSUserDefaults.standardUserDefaults()
    let url = NSBundle.mainBundle().URLForResource("Accounts", withExtension: "json")
    let data = NSData(contentsOfURL: url!)
    do {
      let object = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
      if let array = object as? [[String: AnyObject]]
      {
        for jsonDict in array
        {
          let account = Account(json: jsonDict)
          
          if (defaults.valueForKey(account.pathComponent!) == nil)
          {
            defaults.setObject(jsonDict, forKey: account.pathComponent!)
          }
          else
          {
            // update
            var savedDict = defaults.valueForKey(account.pathComponent!) as! [String: AnyObject]
            savedDict["name"] = account.name
            savedDict["subtitle"] = account.subtitle
            savedDict["logo"] = account.logo
            savedDict["needsAuth"] = account.needsAuth
            savedDict["supportsReservations"] = account.supportsReservations
            savedDict["catalogUrl"] = account.catalogUrl
            savedDict["mainColor"] = account.mainColor
            
            defaults.setObject(savedDict, forKey: account.pathComponent!)
          }
          self.accounts.append(account)
        }
      }
    } catch {
      // Handle Error
    }
  }
  
  @objc func account(id:Int) -> Account?
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
  let defaults: NSUserDefaults
  
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
      setAccountDictionaryKey(userAcceptedEULAKey, toValue: newValue)
    }
  }
  var syncIsEnabled:Bool {
    get {
      guard let result = getAccountDictionaryKey(accountSyncEnabledKey) else { return false }
      return result as! Bool
    }
    set {
      setAccountDictionaryKey(accountSyncEnabledKey, toValue: newValue)
    }
  }
  var userAboveAgeLimit:Bool {
    get {
      guard let result = getAccountDictionaryKey(userAboveAgeKey) else { return false }
      return result as! Bool
    }
    set {
      setAccountDictionaryKey(userAboveAgeKey, toValue: newValue)
    }
  }
  
  init(json: [String: AnyObject])
  {
    defaults = NSUserDefaults.standardUserDefaults()
    
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
  
  private func setAccountDictionaryKey(key: String, toValue value: AnyObject) {
    var savedDict = defaults.valueForKey(self.pathComponent!) as! [String: AnyObject]
    savedDict[key] = value
    defaults.setObject(savedDict, forKey: self.pathComponent!)
  }
  
  private func getAccountDictionaryKey(key: String) -> AnyObject? {
    let savedDict = defaults.valueForKey(self.pathComponent!) as! [String: AnyObject]
    guard let result = savedDict[key] else { return nil }
    return result
  }
}


