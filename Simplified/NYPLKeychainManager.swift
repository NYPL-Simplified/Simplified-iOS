import Foundation
import NYPLAudiobookToolkit

@objcMembers final class NYPLKeychainManager: NSObject {

  private enum KeychainGroups: String {
    case legacyKeychainID = "NLJ22T6E9W.org.nypl.labs.SimplyE"
    case groupKeychainID = "7262U6ST2R.org.nypl.labs.SharedKeychainGroup"
  }

  private static let secClassItems: [String] = [
    kSecClassGenericPassword as String,
    kSecClassInternetPassword as String,
    kSecClassCertificate as String,
    kSecClassKey as String,
    kSecClassIdentity as String
  ]

  private static let secAttrAccessGroups: [String] = [
    KeychainGroups.groupKeychainID.rawValue,
    KeychainGroups.legacyKeychainID.rawValue
  ]

  class func validateKeychain() {
    removeItemsFromPreviousInstalls()
    migrateItemsFromOldKeychain()
    updateKeychainForBackgroundFetch()
    manageFeedbooksData()
    manageFeedbookDrmPrivateKey()
  }

  // The app does not handle DRM Authentication logic when assuming a user
  // is already logged in when finding a username/pin stored in the keychain
  // from a previous app install.
  private class func removeItemsFromPreviousInstalls() {
    if (NYPLSettings.shared.appVersion != nil) {
      return
    }
    Log.info(#file, "Fresh install detected. Purging any existing keychain items...")

    for accessGroup in secAttrAccessGroups {
      for secClass in secClassItems {
        let queryDelete: [String: Any] = [
          kSecClass as String : secClass,
          kSecAttrAccessGroup as String: accessGroup
        ]
        let resultCodeDelete = SecItemDelete(queryDelete as CFDictionary)
        if resultCodeDelete == noErr {
          Log.debug(#file, "\(secClass) item successfully purged from keychain group: \(accessGroup)")
        }
      }
    }
  }

  // Any keychain items in NLJ22T6E9W.org.nypl.labs.SimplyE must be moved to the
  // new shared keychain with a valid, non-wildcard prefix/App ID in order to ensure
  // access in 2.1.0 and beyond. This migration can be phased out and removed
  // from the prov. profile entitlement at a sufficient time that users have moved over (~1 yr).
  private class func migrateItemsFromOldKeychain() {
    for secClass in secClassItems {
      let values = getAllKeyChainItemsOfClass(secClass)
      for (key, value) in values {
        NYPLKeychain.shared().setObject(value,
                                        forKey: key,
                                        accessGroup: KeychainGroups.groupKeychainID.rawValue)
        NYPLKeychain.shared().removeObject(forKey: key,
                                           accessGroup: KeychainGroups.legacyKeychainID.rawValue)
        Log.debug(#file, "Keychain item with key: \"\(key)\" found. Migrating item to new shared group...")
      }
    }
  }

  private class func getAllKeyChainItemsOfClass(_ secClass: String) -> [String:AnyObject] {

    let groupID = "NLJ22T6E9W.org.nypl.labs.SimplyE"
    let query: [String: AnyObject] = [
      kSecClass as String : secClass as AnyObject,
      kSecAttrAccessGroup as String : groupID as AnyObject,
      kSecReturnData as String  : kCFBooleanTrue,
      kSecReturnAttributes as String : kCFBooleanTrue,
      kSecReturnRef as String : kCFBooleanTrue,
      kSecMatchLimit as String : kSecMatchLimitAll
    ]

    var result: AnyObject?
    let lastResultCode = withUnsafeMutablePointer(to: &result) {
      SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
    }

    var values = [String:AnyObject]()
    if lastResultCode == noErr {
      guard let array = result as? Array<Dictionary<String, Any>> else { return values }
      for item in array {
        if let keyData = item[kSecAttrAccount as String] as? Data,
          let valueData = item[kSecValueData as String] as? Data,
          let keyString = NSKeyedUnarchiver.unarchiveObject(with: keyData) as? String {
            Log.debug(#file, "Value found for keychain key: \(keyString)")
            let value = NSKeyedUnarchiver.unarchiveObject(with: valueData) as AnyObject
            values[keyString] = value
        }
      }
    }
    return values
  }

  /// Credentials need to be accessed while the phone is locked during a
  /// background fetch, so those keychain items need their default accessible
  /// level lowered one notch, if not already, to allow access any time after
  /// the first unlock per phone reboot.
  class func updateKeychainForBackgroundFetch() {

    let query: [String: AnyObject] = [
      kSecClass as String : kSecClassGenericPassword,
      kSecAttrAccessible as String : kSecAttrAccessibleWhenUnlocked,  //old default
      kSecReturnData as String  : kCFBooleanTrue,
      kSecReturnAttributes as String : kCFBooleanTrue,
      kSecReturnRef as String : kCFBooleanTrue,
      kSecMatchLimit as String : kSecMatchLimitAll
    ]

    var result: AnyObject?
    let lastResultCode = withUnsafeMutablePointer(to: &result) {
      SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
    }

    var values = [String:AnyObject]()
    if lastResultCode == noErr {
      guard let array = result as? Array<Dictionary<String, Any>> else { return }
      for item in array {
        if let keyData = item[kSecAttrAccount as String] as? Data,
          let valueData = item[kSecValueData as String] as? Data,
          let keyString = NSKeyedUnarchiver.unarchiveObject(with: keyData) as? String {
          let value = NSKeyedUnarchiver.unarchiveObject(with: valueData) as AnyObject
          values[keyString] = value
        }
      }
    }

    for (key, value) in values {
      NYPLKeychain.shared().removeObject(forKey: key)
      NYPLKeychain.shared().setObject(value, forKey: key)
      Log.debug(#file, "Keychain item \"\(key)\" updated with new accessible security level...")
    }
  }
  
  // Load feedbooks profile secrets
  private class func manageFeedbooksData() {
    // Go through each vendor and add their data to keychain so audiobook component can access securely
    for vendor in AudioBookVendors.allCases {
      guard let keyData = NYPLSecrets.feedbookKeys(forVendor: vendor)?.data(using: .utf8),
        let profile = NYPLSecrets.feedbookInfo(forVendor: vendor)["profile"],
        let tag = "feedbook_drm_profile_\(profile)".data(using: .utf8) else {
          Log.error(#file, "Could not load secrets for Feedbook vendor: \(vendor.rawValue)")
          continue
      }
        
      let addQuery: [String: Any] = [
        kSecClass as String: kSecClassKey,
        kSecAttrApplicationTag as String: tag,
        kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        kSecValueData as String: keyData
      ]
      let status = SecItemAdd(addQuery as CFDictionary, nil)
      if status != errSecSuccess && status != errSecDuplicateItem {
        logKeychainError(forVendor: vendor.rawValue, status: status, message: "FeedbookKeyManagement Error:")
      }
    }
  }
    
  private class func manageFeedbookDrmPrivateKey() {
    // DEBUG: Load one key
    DPLAAudiobooks.drmKey { data, error in
      if let error = error {
        Log.error(#file, "Could not receive drm private key from \(DPLAAudiobooks.certificateUrl): \(error.localizedDescription)")
      }
      if let privateKeyData = data {
        let tag = "\(FeedbookDRMPrivateKeyTag)\(AudioBookVendors.cantook.rawValue)".data(using: .utf8)
        let addQuery: [String: Any] = [
          kSecClass as String: kSecClassKey,
          kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
          kSecAttrApplicationTag as String: tag,
          kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
          kSecValueData as String: privateKeyData,
          kSecAttrKeyClass as String: kSecAttrKeyClassPrivate
        ]
          
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        if status != errSecSuccess && status != errSecDuplicateItem {
          logKeychainError(forVendor: AudioBookVendors.cantook.rawValue, status: status, message: "FeedbookDrmPrivateKeyManagement Error:")
        }
      }
    }

//    for vendor in AudioBookVendors.allCases {
//      // Header of PEM key needed to be stripped in order to create SecKey in NYPLAudiobookToolkit
//      // Performing the strip here to avoid converting the data to string back and forth after retrieval
//      guard let privateKeyString = NYPLSecrets.drmCertificate(forVendor: vendor),
//        let privateKeyData = Data(base64Encoded: RSAUtils.stripPEMKeyHeader(privateKeyString)),
//        let tag = "\(FeedbookDRMPrivateKeyTag)\(vendor.rawValue)".data(using: .utf8) else {
//          Log.error(#file, "Could not load drm private key for vendor: \(vendor.rawValue)")
//          continue
//      }
//
//      let addQuery: [String: Any] = [
//        kSecClass as String: kSecClassKey,
//        kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
//        kSecAttrApplicationTag as String: tag,
//        kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
//        kSecValueData as String: privateKeyData,
//        kSecAttrKeyClass as String: kSecAttrKeyClassPrivate
//      ]
//
//      let status = SecItemAdd(addQuery as CFDictionary, nil)
//      if status != errSecSuccess && status != errSecDuplicateItem {
//        logKeychainError(forVendor: vendor.rawValue, status: status, message: "FeedbookDrmPrivateKeyManagement Error:")
//      }
//    }
  }
    
  private class func logKeychainError(forVendor vendor:String, status: OSStatus, message: String) {
    // This is unexpected
    var errMsg = ""
    if #available(iOS 11.3, *) {
      errMsg = (SecCopyErrorMessageString(status, nil) as String?) ?? ""
    }
    if errMsg.isEmpty {
      switch status {
      case errSecUnimplemented:
        errMsg = "errSecUnimplemented"
      case errSecDiskFull:
        errMsg = "errSecDiskFull"
      case errSecIO:
        errMsg = "errSecIO"
      case errSecOpWr:
        errMsg = "errSecOpWr"
      case errSecParam:
        errMsg = "errSecParam"
      case errSecWrPerm:
        errMsg = "errSecWrPerm"
      case errSecAllocate:
        errMsg = "errSecAllocate"
      case errSecUserCanceled:
        errMsg = "errSecUserCanceled"
      case errSecBadReq:
        errMsg = "errSecBadReq"
      default:
        errMsg = "Unknown OSStatus: \(status)"
      }
    }
    
    NYPLErrorLogger.logError(withCode: .keychainItemAddFail,
                             context: "\(NYPLErrorLogger.Context.keychainManagement.rawValue) \(vendor)",
                             message: "\(message) \(errMsg)",
                            metadata: nil)
  }
}
