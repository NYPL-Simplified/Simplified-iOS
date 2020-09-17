import Foundation

@objcMembers class NYPLSettings: NSObject {
  static let shared = NYPLSettings()
  
  static let NYPLAboutSimplyEURLString = "https://librarysimplified.org/simplye/"
  static let NYPLUserAgreementURLString = "https://www.librarysimplified.org/EULA/"
  
  static private let customMainFeedURLKey = "NYPLSettingsCustomMainFeedURL"
  static private let accountMainFeedURLKey = "NYPLSettingsAccountMainFeedURL"
  static private let userHasSeenWelcomeScreenKey = "NYPLUserHasSeenWelcomeScreenKey"
  static private let userPresentedAgeCheckKey = "NYPLUserPresentedAgeCheckKey"
  static private let userSeenFirstTimeSyncMessageKey = "userSeenFirstTimeSyncMessageKey"
  static private let useBetaLibrariesKey = "NYPLUseBetaLibrariesKey"
  static let settingsLibraryAccountsKey = "NYPLSettingsLibraryAccountsKey"
  static private let versionKey = "NYPLSettingsVersionKey"
  
  @objc class func sharedSettings() -> NYPLSettings {
    return NYPLSettings.shared
  }

  // used to handle saml and oauth login. In case of the later, it needs to be configured as universal link
  @objc var authenticationUniversalLink = URL(string: "https://librarysimplified.org/login")!

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
