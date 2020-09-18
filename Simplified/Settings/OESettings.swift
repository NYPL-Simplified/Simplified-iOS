//
//  OESettings.swift
//  Open eBooks
//
//  Created by Kyle Sakai.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

class OESettings : NYPLSettings {
  static let userHasAcceptedEULAKey = "OEUserHasAcceptedEULA"
  
  var userHasAcceptedEULA: Bool {
    get {
      return UserDefaults.standard.bool(forKey: OESettings.userHasAcceptedEULAKey)
    }
    set(b) {
      UserDefaults.standard.set(b, forKey: OESettings.userHasAcceptedEULAKey)
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
      return [NYPLConfiguration.OpenEBooksUUID]
    }
    set(newAccountsList) {
      UserDefaults.standard.set(newAccountsList, forKey: NYPLSettings.settingsLibraryAccountsKey)
      UserDefaults.standard.synchronize()
    }
  }
}
