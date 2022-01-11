//
//  OEMigrations.swift
//  Simplified
//
//  Copyright © 2020 NYPL. All rights reserved.
//

import Foundation

extension NYPLMigrationManager {
  static func runMigrations() {
    // Fetch and parse saved app version from User Defaults
    let appVersionInUserDefaults = NYPLSettings.shared.appVersion ?? ""
    let versionComponents = appVersionInUserDefaults.split(separator: ".").compactMap({ Int($0) })
    Log.info(#function, "AppVersion in UserDefaults: \(appVersionInUserDefaults) - Tokenized: \(versionComponents)")

    // Run through migration stages
    #if FEATURE_DRM_CONNECTOR
    migrate_1_8_1(ifNeededFrom: versionComponents)
    #endif
    migrate_1_9_0(ifNeededFrom: versionComponents)

    #if AXIS
    migrate_2_1_1(ifNeededFrom: versionComponents)
    #endif
  }
  #if FEATURE_DRM_CONNECTOR
  /// v1.8.1
  /// Adept API changed to allow multiple accounts
  /// userID and deviceID will be nil
  /// Need to make transition smooth to multi-account
  /// - Note: this was taken from Open eBooks repo: https://bit.ly/2DHP5sF
  private static func migrate_1_8_1(ifNeededFrom previousVersion: [Int]) -> Void {
    guard !previousVersion.isEmpty, version(previousVersion, isLessThan: [1, 8, 1]) else {
      return
    }

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
  #endif

  private static func migrate_1_9_0(ifNeededFrom previousVersion: [Int]) -> Void {
    // we run this even if previous version is empty because this migration
    // involves keychain items, which are persisted even after the app is
    // uninstalled.
    guard version(previousVersion, isLessThan: [1, 9, 0]) else {
      return
    }

    Log.info(#file, "Running 1.9.0 migration")

    // translate old User settings from keychain
    let user = NYPLUserAccount.sharedAccount(libraryUUID: NYPLConfiguration.OpenEBooksUUIDProd)
    let keychain = NYPLKeychain.shared()

    if let oldBarcode = keychain?.object(forKey: "OpenEbooksAccountBarcode") as? String,
      let oldPIN = keychain?.object(forKey: "OpenEbooksAccountPIN") as? String {

      Log.info(#function, "oldBarcode (hashed)=\(oldBarcode.md5hex())")

      // only set it if we are actually upgrading. If user had removed the app
      // do not set it because it would be jarring to see yourself signed in.
      if !previousVersion.isEmpty {
        user.setBarcode(oldBarcode, PIN: oldPIN)
      }

      keychain?.removeObject(forKey: "OpenEbooksAccountBarcode")
      keychain?.removeObject(forKey: "OpenEbooksAccountPIN")
    } else {
      Log.info(#function, "No Barcode+Pin combo found while migrating from \(previousVersion)")
    }

    if let oldAdobeToken = keychain?.object(forKey: "OpenEbooksAccountAdobeTokenKey") as? String,
      let oldPatron = keychain?.object(forKey: "OpenEbooksAccountPatronKey") as? [String: Any] {

      Log.info(#function, "oldPatron=\(oldPatron)")

      // only set it if we are actually upgrading.
      if !previousVersion.isEmpty {
        user.setAdobeToken(oldAdobeToken, patron: oldPatron)
      }

      keychain?.removeObject(forKey: "OpenEbooksAccountAdobeTokenKey")
      keychain?.removeObject(forKey: "OpenEbooksAccountPatronKey")
    } else {
      Log.info(#function, "No AdobeToken+Patron combo found while migrating from \(previousVersion)")
    }

    if let oldAuthToken = keychain?.object(forKey: "OpenEbooksAccountAuthTokenKey") as? String {
      if !previousVersion.isEmpty {
        user.setAuthToken(oldAuthToken)
      }
      keychain?.removeObject(forKey: "OpenEbooksAccountAuthTokenKey")
    } else {
      Log.info(#function, "No AuthToken found while migrating from \(previousVersion)")
    }

    if let oldAdobeVendor = keychain?.object(forKey: "OpenEbooksAccountAdobeVendorKey") as? String {
      Log.info(#function, "oldAdobeVendor=\(oldAdobeVendor)")
      if !previousVersion.isEmpty {
        user.setAdobeVendor(oldAdobeVendor)
      }
      keychain?.removeObject(forKey: "OpenEbooksAccountAdobeVendorKey")
    } else {
      Log.info(#function, "No AdobeVendor found while migrating from \(previousVersion)")
    }

    if let oldProvider = keychain?.object(forKey: "OpenEbooksAccountProviderKey") as? String {
      Log.info(#function, "oldProvider=\(oldProvider)")
      if !previousVersion.isEmpty {
        user.setProvider(oldProvider)
      }
      keychain?.removeObject(forKey: "OpenEbooksAccountProviderKey")
    } else {
      Log.info(#function, "No Provider found while migrating from \(previousVersion)")
    }

    if let oldUserID = keychain?.object(forKey: "OpenEbooksAccountUserIDKey") as? String {
      Log.info(#function, "oldUserID=\(oldUserID)")
      if !previousVersion.isEmpty {
        user.setUserID(oldUserID)
      }
      keychain?.removeObject(forKey: "OpenEbooksAccountUserIDKey")
    } else {
      Log.info(#function, "No userID found while migrating from \(previousVersion)")
    }

    if let oldDeviceID = keychain?.object(forKey: "OpenEbooksAccountDeviceIDKey") as? String {
      Log.info(#function, "oldDeviceID=\(oldDeviceID)")
      if !previousVersion.isEmpty {
        user.setDeviceID(oldDeviceID)
      }
      keychain?.removeObject(forKey: "OpenEbooksAccountDeviceIDKey")
    } else {
      Log.info(#function, "No DeviceID found while migrating from \(previousVersion)")
    }
  }

  /// Since v2.1.0 OE supports only Axis DRM books. Books
  /// previously downloaded with Adobe DRM are treated as unsupported, therefore
  /// not openable anymore in the ereader. (This was necessary because the
  /// contract with Adobe ended at a hard date.)
  /// To avoid confusion, and since the same books are redownloadable in Axis
  /// format, we wipe out all downloaded content from disk, and change the state
  /// of those books so that the user knows that they need to be downloaded
  /// again.
  private static func migrate_2_1_1(ifNeededFrom previousVersion: [Int]) -> Void {
    guard !previousVersion.isEmpty, version(previousVersion, isLessThan: [2, 1, 1]) else {
      return
    }

    let accountMgr = AccountsManager.shared
    Log.info(#function, "accountMgr.currentAccountId=\(String(describing: accountMgr.currentAccountId))")

    // we need to set up the account sets before resetting the download center,
    // because otherwise the reset function will do nothing.
    accountMgr.updateAccountSet { [weak accountMgr] _ in
      Log.info(#function, "accountMgr.currentAccount.uuid=\(String(describing: accountMgr?.currentAccount?.uuid))")

      // Wipe out all downloaded books from disk.
      NYPLMyBooksDownloadCenter.shared()?.reset()

      let registry = NYPLBookRegistry.shared()

      // Change the book state for our books so that they are downloadable
      // again. Note that there may be other sync operations in progress
      // already (syncResettingCache:completionHandler:backgroundFetchHandler:)
      // but those do not interfere with the code below because they won't
      // change the book state. This dependency is not enforced in code and
      // therefore it is very fragile. The need for this migration is
      // short lived since users won't be able to check out books in Adobe
      // format anymore.
      if let allBooks = NYPLBookRegistry.shared().allBooks as? [NYPLBook] {
        for book in allBooks {
          registry.resetStateToDownloadNeeded(forIdentifier: book.identifier)
        }
      }
      registry.save()
    }
  }
}
