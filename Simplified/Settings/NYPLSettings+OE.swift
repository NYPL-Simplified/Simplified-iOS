//
//  NYPLSettings+OE.swift
//  Open eBooks
//
//  Created by Kyle Sakai.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

extension NYPLSettings: NYPLUniversalLinksSettings {
  /// Used to handle Clever sign-ins via OAuth in Open eBooks. 
  @objc var authenticationUniversalLink: URL {
    // TODO: SIMPLY-3050 this is a dev URL. Replace with production one.
    return URL(string: "https://dev-librarysimplified.pantheonsite.io/callbacks/OpenEbooks")!
  }
}

extension NYPLSettings {
  static let userHasSeenWelcomeScreenKey = "NYPLSettingsUserFinishedTutorial"

  var settingsAccountsList: [String] {
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
