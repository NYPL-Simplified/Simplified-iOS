import Foundation

extension Notification.Name {
  static let NYPLSettingsDidChange = Notification.Name("NYPLSettingsDidChange")
  static let NYPLCurrentAccountDidChange = Notification.Name("NYPLCurrentAccountDidChange")
  static let NYPLCatalogDidLoad = Notification.Name("NYPLCatalogDidLoad")
  static let NYPLSyncBegan = Notification.Name("NYPLSyncBegan")
  static let NYPLSyncEnded = Notification.Name("NYPLSyncEnded")
  static let NYPLUseBetaDidChange = Notification.Name("NYPLUseBetaDidChange")
}

@objc extension NSNotification {
  public static let NYPLSettingsDidChange = Notification.Name.NYPLSettingsDidChange
  public static let NYPLCurrentAccountDidChange = Notification.Name.NYPLCurrentAccountDidChange
  public static let NYPLCatalogDidLoad = Notification.Name.NYPLCatalogDidLoad
  public static let NYPLSyncBegan = Notification.Name.NYPLSyncBegan
  public static let NYPLSyncEnded = Notification.Name.NYPLSyncEnded
  public static let NYPLUseBetaDidChange = Notification.Name.NYPLUseBetaDidChange
}

let Version = 1

let NYPLAcknowledgementsURLString = "http://www.librarysimplified.org/acknowledgments.html"
let NYPLUserAgreementURLString = "http://www.librarysimplified.org/EULA.html"

@objcMembers class NYPLSettings: NSObject {
  static let shared = NYPLSettings()
  
  static let NYPLAcknowledgementsURLString = "http://www.librarysimplified.org/acknowledgments.html"
  static let NYPLUserAgreementURLString = "http://www.librarysimplified.org/EULA.html"
  
  static let customMainFeedURLKey = "NYPLSettingsCustomMainFeedURL"
  static let accountMainFeedURLKey = "NYPLSettingsAccountMainFeedURL"
  static let userHasSeenWelcomeScreenKey = "NYPLUserHasSeenWelcomeScreenKey"
  static let userPresentedAgeCheckKey = "NYPLUserPresentedAgeCheckKey"
  static let userSeenFirstTimeSyncMessageKey = "userSeenFirstTimeSyncMessageKey"
  static let useBetaLibrariesKey = "NYPLUseBetaLibrariesKey"
  static let settingsLibraryAccountsKey = "NYPLSettingsLibraryAccountsKey"
  static let versionKey = "NYPLSettingsVersionKey"
  
  @objc class func sharedSettings() -> NYPLSettings {
    return NYPLSettings.shared
  }

  // Set to nil (the default) if no custom feed should be used.
  var customMainFeedURL: URL? {
    get {
      return UserDefaults.standard.url(forKey: NYPLSettings.customMainFeedURLKey)
    }
    set(customUrl) {
      if (customUrl == self.customMainFeedURL) {
        return
      }
      UserDefaults.standard.set(customUrl, forKey: NYPLSettings.customMainFeedURLKey)
      UserDefaults.standard.synchronize()
      NotificationCenter.default.post(name: Notification.Name.NYPLSettingsDidChange, object: self)
    }
  }
  
  var accountMainFeedURL: URL? {
    get {
      return UserDefaults.standard.url(forKey: NYPLSettings.accountMainFeedURLKey)
    }
    set(mainFeedUrl) {
      if (mainFeedUrl == self.accountMainFeedURL) {
        return
      }
      UserDefaults.standard.set(mainFeedUrl, forKey: NYPLSettings.accountMainFeedURLKey)
      UserDefaults.standard.synchronize()
      NotificationCenter.default.post(name: Notification.Name.NYPLSettingsDidChange, object: self)
    }
  }
  
  var userHasSeenWelcomeScreen: Bool {
    get {
      return UserDefaults.standard.bool(forKey: NYPLSettings.userHasSeenWelcomeScreenKey)
    }
    set(b) {
      UserDefaults.standard.set(b, forKey: NYPLSettings.userHasSeenWelcomeScreenKey)
      UserDefaults.standard.synchronize()
    }
  }
  
  var userPresentedAgeCheck: Bool {
    get {
      return UserDefaults.standard.bool(forKey: NYPLSettings.userPresentedAgeCheckKey)
    }
    set(b) {
      UserDefaults.standard.set(b, forKey: NYPLSettings.userPresentedAgeCheckKey)
      UserDefaults.standard.synchronize()
    }
  }
  
  var userHasSeenFirstTimeSyncMessage: Bool {
    get {
      return UserDefaults.standard.bool(forKey: NYPLSettings.userSeenFirstTimeSyncMessageKey)
    }
    set(b) {
      UserDefaults.standard.set(b, forKey: NYPLSettings.userSeenFirstTimeSyncMessageKey)
      UserDefaults.standard.synchronize()
    }
  }
  
  var useBetaLibraries: Bool {
    get {
      return UserDefaults.standard.bool(forKey: NYPLSettings.useBetaLibrariesKey)
    }
    set(b) {
      UserDefaults.standard.set(b, forKey: NYPLSettings.useBetaLibrariesKey)
      UserDefaults.standard.synchronize()
      NotificationCenter.default.post(name: NSNotification.Name.NYPLUseBetaDidChange, object: self)
    }
  }
  
  var settingsAccountsList: [String] {
    get {
      if let libraryAccounts = UserDefaults.standard.array(forKey: NYPLSettings.settingsLibraryAccountsKey) {
        return libraryAccounts as! [String]
      }
      
      // Avoid crash in case currentLibrary isn't set yet
      var accountsList = [String]()
      if let currentLibrary = AccountsManager.shared.currentAccount?.uuid {
        accountsList.append(currentLibrary)
      }
      accountsList.append(AccountsManager.NYPLAccountUUIDs[2])
      self.settingsAccountsList = accountsList
      return accountsList
    }
    set(newAccountsList) {
      UserDefaults.standard.set(newAccountsList, forKey: NYPLSettings.settingsLibraryAccountsKey)
      UserDefaults.standard.synchronize()
    }
  }
  
  var appVersion: String? {
    get {
      return UserDefaults.standard.string(forKey: NYPLSettings.versionKey)
    }
    set(versionString) {
      UserDefaults.standard.set(versionString, forKey: NYPLSettings.versionKey)
      UserDefaults.standard.synchronize()
    }
  }
}
