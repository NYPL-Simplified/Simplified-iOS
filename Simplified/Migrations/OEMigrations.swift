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
    let appVersion = NYPLSettings.shared.appVersion ?? ""
    let appVersionTokens = appVersion.split(separator: ".").compactMap({ Int($0) })

    // Run through migration stages
    if versionIsLessThan(appVersionTokens, [1, 8, 1]) { // v1.8.1
      migrate_1_8_1();
    }
  }

  // v1.8.1
  // Adept API changed to allow multiple accounts
  // userID and deviceID will be nil
  // Need to make transition smooth to multi-account
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
