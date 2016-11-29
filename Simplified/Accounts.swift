import Foundation

let currentAccountIdentifierKey             = "NYPLCurrentAccountIdentifier"
let customMainFeedURLKey                    = "NYPLSettingsCustomMainFeedURL"
let accountMainFeedURLKey                   = "NYPLSettingsAccountMainFeedURL"
let renderingEngineKey                      = "NYPLSettingsRenderingEngine"
let userAboveAgeKey                         = "NYPLSettingsUserAboveAgeKey"
let userAcceptedEULAKey                     = "NYPLSettingsUserAcceptedEULA"
let userPresentedWelcomeScreenKey           = "NYPLUserPresentedWelcomeScreenKey"
let eulaURLKey                              = "NYPLSettingsEULAURL"
let privacyPolicyURLKey                     = "NYPLSettingsPrivacyPolicyURL"
let acknowledgmentsURLKey                   = "NYPLSettingsAcknowledgmentsURL"
let contentLicenseURLKey                    = "NYPLSettingsContentLicenseURL"
let currentCardApplicationSerializationKey  = "NYPLSettingsCurrentCardApplicationSerialized"
let settingsLibraryAccountsKey              = "NYPLSettingsLibraryAccountsKey"
let annotationsURLKey                       = "NYPLSettingsAnnotationsURL"
let accountSyncEnabledKey                   = "NYPLAccountSyncEnabledKey"


/// Manage the library accounts for the app. Initialized with JSON.
final class AccountsManager: NSObject
{
  static let shared = AccountsManager()
  
  // For Objective-C classes
  @objc class func sharedInstance() -> AccountsManager
  {
    return AccountsManager.shared
  }
  
  var accounts = [Account]()
  var currentAccount: Account {
    get {
      return account(NSUserDefaults.standardUserDefaults().integerForKey(currentAccountIdentifierKey))!
    }
    set {
      NSUserDefaults.standardUserDefaults().setInteger(currentAccount.id, forKey: currentAccountIdentifierKey)
    }
  }

  private override init()
  {
    let url = NSBundle.mainBundle().URLForResource("Accounts", withExtension: "json")
    let data = NSData(contentsOfURL: url!)
    do {
      let object = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
      if let array = object as? [[String: AnyObject]]
      {
        for jsonDict in array
        {
          let account = Account(json: jsonDict)
          
          if (NSUserDefaults.standardUserDefaults().valueForKey(account.pathComponent!) == nil)
          {
            NSUserDefaults.standardUserDefaults().setObject(jsonDict, forKey: account.pathComponent!)
          }
          else
          {
            // update
            var savedDict = NSUserDefaults.standardUserDefaults().valueForKey(account.pathComponent!) as! [String: AnyObject]
            savedDict["name"] = account.name
            savedDict["subtitle"] = account.subtitle
            savedDict["logo"] = account.logo
            savedDict["needsAuth"] = account.needsAuth
            savedDict["supportsReservations"] = account.supportsReservations
            savedDict["catalogUrl"] = account.catalogUrl
            savedDict["mainColor"] = account.mainColor
            
            NSUserDefaults.standardUserDefaults().setObject(savedDict, forKey: account.pathComponent!)
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
  
  func changeCurrentAccountWith(identifier id: Int)
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
      return NSUserDefaults.standardUserDefaults().boolForKey(userAcceptedEULAKey + "_\(self.id)")
    }
    set {
      defaults.setBool(eulaIsAccepted, forKey: userAcceptedEULAKey + "_\(self.id)")
    }
  }
  var syncIsEnabled:Bool {
    get {
      return NSUserDefaults.standardUserDefaults().boolForKey(accountSyncEnabledKey + "_\(self.id)")
    }
    set {
      defaults.setBool(syncIsEnabled, forKey: accountSyncEnabledKey + "_\(self.id)")
    }
  }
  var userAboveAgeLimit:Bool {
    get {
      return NSUserDefaults.standardUserDefaults().boolForKey(userAboveAgeKey + "_\(self.id)")
    }
    set {
      defaults.setBool(userAboveAgeLimit, forKey: userAboveAgeKey + "_\(self.id)")
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
}


