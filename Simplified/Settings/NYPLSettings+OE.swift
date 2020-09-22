//
//  NYPLSettings+OE.swift
//  Open eBooks
//
//  Created by Kyle Sakai.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

extension NYPLSettings {
  /// Used to handle OAuth sign-ins. For example, Clever authentication uses
  /// this URL for redirecting to the app after authenticating in Safari.
  /// This requires configurion setting Universal Links on the server.
  @objc var authenticationUniversalLink: URL {
    return URL(string: "https://www.librarysimplified.org/callbacks/OpenEbooks")!
  }

  static let userHasAcceptedEULAKey = "OEUserHasAcceptedEULA"

  var userHasAcceptedEULA: Bool {
    get {
      return UserDefaults.standard.bool(forKey: NYPLSettings.userHasAcceptedEULAKey)
    }
    set(b) {
      UserDefaults.standard.set(b, forKey: NYPLSettings.userHasAcceptedEULAKey)
      UserDefaults.standard.synchronize()
    }
  }

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
