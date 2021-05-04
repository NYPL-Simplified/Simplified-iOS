//
//  NYPLSettings+SE.swift
//  Simplified
//
//  Created by Ettore Pasquini on 9/17/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

extension NYPLSettings: NYPLUniversalLinksSettings {
  /// Used to handle Clever and SAML sign-ins in SimplyE.
  @objc var universalLinksURL: URL {
    return URL(string: "https://librarysimplified.org/callbacks/SimplyE")!
  }
}

extension NYPLSettings {
  static let userHasSeenWelcomeScreenKey = "NYPLUserHasSeenWelcomeScreenKey"
  
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
      accountsList.append(AccountsManager.shared.SimplyEAccountUUID)
      self.settingsAccountsList = accountsList
      return accountsList
    }
    set(newAccountsList) {
      UserDefaults.standard.set(newAccountsList, forKey: NYPLSettings.settingsLibraryAccountsKey)
      UserDefaults.standard.synchronize()
    }
  }
}
