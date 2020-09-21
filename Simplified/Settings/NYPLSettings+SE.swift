//
//  NYPLSettings+SE.swift
//  Simplified
//
//  Created by Ettore Pasquini on 9/17/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

extension NYPLSettings {
  /// Used to handle OAuth sign-ins. For example, Clever authentication uses
  /// this URL for redirecting to the app after authenticating in Safari.
  /// This requires configurion setting Universal Links on the server.
  @objc var authenticationUniversalLink: URL {
    return URL(string: "https://www.librarysimplified.org/callbacks/SimplyE")!
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
}
