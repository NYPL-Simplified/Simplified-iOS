//
//  OEMigrations.swift
//  Simplified
//
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

extension NYPLMigrationManager {
  static func runMigrations() {
    // Fetch and parse app version
    let appVersionInUserDefaults = NYPLSettings.shared.appVersion ?? ""
    let appVersionInUserDefaultsTokens = appVersionInUserDefaults.split(separator: ".").compactMap({ Int($0) })

    // Run through migration stages
    Log.info(#file, "AppVersion in UserDefaults: \(appVersionInUserDefaultsTokens)")
    if versionIsLessThan(appVersionInUserDefaultsTokens, [1, 7, 7]) {
      migrate_1_7_7();
    }

    if versionIsLessThan(appVersionInUserDefaultsTokens, [1, 8, 1]) {
      migrate_1_8_1();
    }
  }

  /// v1.7.7
  /// Account IDs are changing, so we need to migrate resources accordingly
  /// - Note: this was taken from original Open eBooks PR: https://bit.ly/32cPlt8
  private static func migrate_1_7_7() -> Void {
    Log.info(#file, "Running 1.7.7 migration")

    // Translate account to Simplified
    AccountsManager.shared.loadCatalogs { success in
      Log.debug(#file, "Ran 1.7.7 migration call: \(success)")
      AccountsManager.shared.currentAccount = AccountsManager.shared.account(NYPLConfiguration.OpenEBooksUUID)
    }
  }

  /// v1.8.1
  /// Adept API changed to allow multiple accounts
  /// userID and deviceID will be nil
  /// Need to make transition smooth to multi-account
  /// - Note: this was taken from Open eBooks repo: https://bit.ly/2DHP5sF
  private static func migrate_1_8_1() -> Void {
    Log.info(#file, "Running 1.8.1 migration")
    let nyplAccount = NYPLUserAccount.sharedAccount()

    if nyplAccount.userID == nil && nyplAccount.deviceID == nil {
      var adobeUserID: NSString? = nil
      var adobeDeviceID: NSString? = nil
      NYPLADEPT.sharedInstance()?.getMigrationUserID(&adobeUserID,
                                                     deviceID: &adobeDeviceID)
      if let adobeUserID = adobeUserID {
        nyplAccount.setUserID(String(adobeUserID))
      }
      if let adobeDeviceID = adobeDeviceID {
        nyplAccount.setDeviceID(String(adobeDeviceID))
      }
    }
  }
}
