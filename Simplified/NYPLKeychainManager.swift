import Foundation

final class NYPLKeychainManager: NSObject {

  private static let secClassItems: [String] = [
    kSecClassGenericPassword as String,
    kSecClassInternetPassword as String,
    kSecClassCertificate as String,
    kSecClassKey as String,
    kSecClassIdentity as String
  ]

  private static let secAttrAccessGroups: [String] = [
    "7262U6ST2R.org.nypl.labs.SharedKeychainGroup",
    "NLJ22T6E9W.org.nypl.labs.SimplyE"
  ]

  class func validateKeychain() {
    removeItemsFromPreviousInstalls()
    migrateItemsFromOldKeychain()
  }

  // The app does not handle DRM Authentication logic when assuming a user
  // is already logged in when finding a username/pin stored in the keychain
  // from a previous app install.
  private class func removeItemsFromPreviousInstalls() {
    if (UserDefaults.standard.object(forKey: userHasSeenWelcomeScreenKey) != nil) {
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
        NYPLKeychain.shared().setObject(value, forKey: key)
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
    Log.debug(#file, "Result of keychain query: \(lastResultCode)")

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

}
