extension Notification.Name {
  static let OEAppDelegateDidReceiveCleverRedirectURL = Notification.Name("OEAppDelegateDidReceiveCleverRedirectURL")
}

class OESettings : NYPLSettings {
  static var oeShared = OESettings()
  
  static let userHasAcceptedEULA = "OEUserHasAcceptedEULA"
  
  var userHasAcceptedEULA: Bool {
    get {
      return UserDefaults.standard.bool(forKey: OESettings.userHasAcceptedEULA)
    }
    set(b) {
      UserDefaults.standard.set(b, forKey: OESettings.userHasAcceptedEULA)
      UserDefaults.standard.synchronize()
    }
  }
  
  // MARK: NYPLSettings
  
  override var settingsAccountsList: [String] {
    get {
      if let libraryAccounts = UserDefaults.standard.array(forKey: NYPLSettings.settingsLibraryAccountsKey) {
        return libraryAccounts as! [String]
      }
      
      // Avoid crash in case currentLibrary isn't set yet
      return [OEConfiguration.OpenEBooksUUID]
    }
    set(newAccountsList) {
      UserDefaults.standard.set(newAccountsList, forKey: NYPLSettings.settingsLibraryAccountsKey)
      UserDefaults.standard.synchronize()
    }
  }
}
