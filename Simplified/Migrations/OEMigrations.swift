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
    Log.info(#function, "AppVersion in UserDefaults: \(appVersionInUserDefaultsTokens)")

    if versionIsLessThan(appVersionInUserDefaultsTokens, [1, 8, 1]) {
      migrate_1_8_1();
    }

    if versionIsLessThan(appVersionInUserDefaultsTokens, [1, 9, 0]) {
      migrate_1_9_0();
    }
  }

  /// v1.8.1
  /// Adept API changed to allow multiple accounts
  /// userID and deviceID will be nil
  /// Need to make transition smooth to multi-account
  /// - Note: this was taken from Open eBooks repo: https://bit.ly/2DHP5sF
  private static func migrate_1_8_1() -> Void {
    Log.info(#function, "Running 1.8.1 migration")
    let nyplAccount = NYPLUserAccount.sharedAccount()

    if nyplAccount.userID == nil && nyplAccount.deviceID == nil {
      var adobeUserID: NSString? = nil
      var adobeDeviceID: NSString? = nil
      NYPLADEPT.sharedInstance()?.getMigrationUserID(&adobeUserID,
                                                     deviceID: &adobeDeviceID)
      if let adobeUserID = adobeUserID {
        Log.info(#function, "1.8.1: AdobeUserID=\(adobeUserID)")
        nyplAccount.setUserID(String(adobeUserID))
      }
      if let adobeDeviceID = adobeDeviceID {
        Log.info(#function, "1.8.1: AdobeDeviceID=\(adobeDeviceID)")
        nyplAccount.setDeviceID(String(adobeDeviceID))
      }
    }
  }

  private static func migrate_1_9_0() -> Void {
    Log.info(#file, "Running 1.9.0 migration")

    // translate old User settings from keychain
    let user = NYPLUserAccount.sharedAccount(libraryUUID: NYPLConfiguration.OpenEBooksUUIDProd)
    let keychain = NYPLKeychain.shared()

    if let oldBarcode = keychain?.object(forKey: "OpenEbooksAccountBarcode") as? String,
      let oldPIN = keychain?.object(forKey: "OpenEbooksAccountPIN") as? String {

      user.setBarcode(oldBarcode, PIN: oldPIN)
      keychain?.removeObject(forKey: "OpenEbooksAccountBarcode")
      keychain?.removeObject(forKey: "OpenEbooksAccountPIN")
    } else {
      Log.info(#function, "No Barcode+Pin combo found while migrating from pre 1.9.0")
    }

    if let oldAdobeToken = keychain?.object(forKey: "OpenEbooksAccountAdobeTokenKey") as? String,
      let oldPatron = keychain?.object(forKey: "OpenEbooksAccountPatronKey") as? [String: Any] {

      user.setAdobeToken(oldAdobeToken, patron: oldPatron)
      keychain?.removeObject(forKey: "OpenEbooksAccountAdobeTokenKey")
      keychain?.removeObject(forKey: "OpenEbooksAccountPatronKey")
    } else {
      Log.info(#function, "No AdobeToken+Patron combo found while migrating from pre 1.9.0")
    }

    if let oldAuthToken = keychain?.object(forKey: "OpenEbooksAccountAuthTokenKey") as? String {
      user.setAuthToken(oldAuthToken)
      keychain?.removeObject(forKey: "OpenEbooksAccountAuthTokenKey")
    } else {
      Log.info(#function, "No AuthToken found while migrating from pre 1.9.0")
    }

    if let oldAdobeVendor = keychain?.object(forKey: "OpenEbooksAccountAdobeVendorKey") as? String {
      user.setAdobeVendor(oldAdobeVendor)
      keychain?.removeObject(forKey: "OpenEbooksAccountAdobeVendorKey")
    } else {
      Log.info(#function, "No AdobeVendor found while migrating from pre 1.9.0")
    }

    if let oldProvider = keychain?.object(forKey: "OpenEbooksAccountProviderKey") as? String {
      user.setProvider(oldProvider)
      keychain?.removeObject(forKey: "OpenEbooksAccountProviderKey")
    } else {
      Log.info(#function, "No Provider found while migrating from pre 1.9.0")
    }

    if let oldUserID = keychain?.object(forKey: "OpenEbooksAccountUserIDKey") as? String {
      Log.info(#function, "oldUserID=\(oldUserID)")
      user.setUserID(oldUserID)
      keychain?.removeObject(forKey: "OpenEbooksAccountUserIDKey")
    } else {
      Log.info(#function, "No userID found while migrating from pre 1.9.0")
    }

    if let oldDeviceID = keychain?.object(forKey: "OpenEbooksAccountDeviceIDKey") as? String {
      Log.info(#function, "oldDeviceID=\(oldDeviceID)")
      user.setDeviceID(oldDeviceID)
      keychain?.removeObject(forKey: "OpenEbooksAccountDeviceIDKey")
    } else {
      Log.info(#function, "No DeviceID found while migrating from pre 1.9.0")
    }
  }

}
