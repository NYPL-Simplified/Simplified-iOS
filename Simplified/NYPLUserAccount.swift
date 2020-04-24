import Foundation

extension Notification.Name {
  static let NYPLUserAccountDidChange = Notification.Name("NYPLUserAccountDidChangeNotification")
  static let NYPLUserAccountLoginDidChange = Notification.Name("NYPLUserAccountLoginDidChangeNotification")
}

@objc extension NSNotification {
  public static let NYPLUserAccountDidChange = Notification.Name.NYPLUserAccountDidChange
  public static let NYPLUserAccountLoginDidChange = Notification.Name.NYPLUserAccountLoginDidChange
}

@objcMembers class NYPLUserAccount : NSObject {
  static private let shared = NYPLUserAccount()
  private let accountInfoLock = NSRecursiveLock()
    
  private var authorizationIdentifierKey = "NYPLAccountAuthorization"
  private var barcodeKey = "NYPLAccountBarcode"
  private var PINKey = "NYPLAccountPIN"
  private var adobeTokenKey = "NYPLAccountAdobeTokenKey"
  private var licensorKey = "NYPLAccountLicensorKey"
  private var patronKey = "NYPLAccountPatronKey"
  private var authTokenKey = "NYPLAccountAuthTokenKey"
  private var adobeVendorKey = "NYPLAccountAdobeVendorKey"
  private var providerKey = "NYPLAccountProviderKey"
  private var userIDKey = "NYPLAccountUserIDKey"
  private var deviceIDKey = "NYPLAccountDeviceIDKey"

  @objc class func sharedAccount() -> NYPLUserAccount
  {
    return sharedAccount(libraryUUID: AccountsManager.shared.currentAccount?.uuid)
  }
    
  @objc(sharedAccount:)
  class func sharedAccount(libraryUUID: String?) -> NYPLUserAccount
  {
    shared.accountInfoLock.lock()
    defer {
        shared.accountInfoLock.unlock()
    }
    if let uuid = libraryUUID,
        uuid != AccountsManager.NYPLAccountUUIDs[0]
    {
      shared.barcodeKey = "NYPLAccountBarcode_\(uuid)"
      shared.authorizationIdentifierKey = "NYPLAccountAuthorization_\(uuid)"
      shared.PINKey = "NYPLAccountPIN_\(uuid)"
      shared.adobeTokenKey = "NYPLAccountAdobeTokenKey_\(uuid)"
      shared.patronKey = "NYPLAccountPatronKey_\(uuid)"
      shared.authTokenKey = "NYPLAccountAuthTokenKey_\(uuid)"
      shared.adobeVendorKey = "NYPLAccountAdobeVendorKey_\(uuid)"
      shared.providerKey = "NYPLAccountProviderKey_\(uuid)"
      shared.userIDKey = "NYPLAccountUserIDKey_\(uuid)"
      shared.deviceIDKey = "NYPLAccountDeviceIDKey_\(uuid)"
      shared.licensorKey = "NYPLAccountLicensorKey_\(uuid)"
    } else {
      shared.barcodeKey = "NYPLAccountBarcode"
      shared.authorizationIdentifierKey = "NYPLAccountAuthorization"
      shared.PINKey = "NYPLAccountPIN"
      shared.adobeTokenKey = "NYPLAccountAdobeTokenKey"
      shared.patronKey = "NYPLAccountPatronKey"
      shared.authTokenKey = "NYPLAccountAuthTokenKey"
      shared.adobeVendorKey = "NYPLAccountAdobeVendorKey"
      shared.providerKey = "NYPLAccountProviderKey"
      shared.userIDKey = "NYPLAccountUserIDKey"
      shared.deviceIDKey = "NYPLAccountDeviceIDKey"
      shared.licensorKey = "NYPLAccountLicensorKey"
    }
    
    return shared
  }
   
  // MARK: - Check
    
  func hasBarcodeAndPIN() -> Bool {
    return barcode != nil && PIN != nil
  }
  
  func hasAuthToken() -> Bool {
    return authToken != nil
  }
  
  func hasAdobeToken() -> Bool {
    return adobeToken != nil
  }
  
  func hasLicensor() -> Bool {
    return licensor != nil
  }
  
  func hasCredentials() -> Bool {
    return hasAuthToken() || hasBarcodeAndPIN()
  }
    
  // MARK: - GET
    
  var barcode: String? {
    return NYPLKeychain.shared()?.object(forKey: barcodeKey) as? String
  }
    
  var authorizationIdentifier: String? {
    return NYPLKeychain.shared()?.object(forKey: authorizationIdentifierKey) as? String
  }
  
  var PIN: String? {
    return NYPLKeychain.shared()?.object(forKey: PINKey) as? String
  }
  
  var deviceID: String? {
    return NYPLKeychain.shared()?.object(forKey: deviceIDKey) as? String
  }
  
  var userID: String? {
    return NYPLKeychain.shared()?.object(forKey: userIDKey) as? String
  }
    
  var adobeVendor: String? {
    return NYPLKeychain.shared()?.object(forKey: adobeVendorKey) as? String
  }
    
  var provider: String? {
    return NYPLKeychain.shared()?.object(forKey: providerKey) as? String
  }
    
  var patron: [String:Any]? {
    return NYPLKeychain.shared()?.object(forKey: patronKey) as? [String:Any]
  }
    
  var patronFullName: String? {
    if let patron = patron,
      let name = patron["name"] as? [String:String]
    {
      var fullname = ""
      
      if let first = name["first"] {
        fullname.append(first)
      }
      
      if let middle = name["middle"] {
        if fullname.count > 0 {
          fullname.append(" ")
        }
        fullname.append(middle)
      }
      
      if let last = name["last"] {
        if fullname.count > 0 {
          fullname.append(" ")
        }
        fullname.append(last)
      }
      
      return fullname.count > 0 ? fullname : nil
    }
    
    return nil
  }
    
  var authToken: String? {
    return NYPLKeychain.shared()?.object(forKey: authTokenKey) as? String
  }
    
  var adobeToken: String? {
    return NYPLKeychain.shared()?.object(forKey: adobeTokenKey) as? String
  }
    
  var licensor: [String:Any]? {
    return NYPLKeychain.shared()?.object(forKey: licensorKey) as? [String:Any]
  }
    
  // MARK: - SET
    
  @objc(setBarcode:PIN:)
  func setBarcode(_ barcode: String, PIN: String) {
    guard let sharedKeychain = NYPLKeychain.shared() else {
      return
    }
    
    accountInfoLock.lock()
    defer {
        accountInfoLock.unlock()
    }
    
    sharedKeychain.setObject(barcode, forKey: barcodeKey)
    sharedKeychain.setObject(PIN, forKey: PINKey)
    
    // make sure to set the barcode related to the current account (aka library)
    // not the one we just signed in to, because we could have signed in into
    // library A, but still browsing the catalog of library B.
    NYPLErrorLogger.setUserID(NYPLUserAccount.sharedAccount().barcode)
    
    NotificationCenter.default.post(
      name: Notification.Name.NYPLUserAccountDidChange,
      object: self
    )
  }
    
  @objc(setAdobeToken:patron:)
  func setAdobeToken(_ token: String, patron: [String : Any]) {
    guard let sharedKeychain = NYPLKeychain.shared() else {
      return
    }
    
    accountInfoLock.lock()
    defer {
        accountInfoLock.unlock()
    }
    
    sharedKeychain.setObject(token, forKey: adobeTokenKey)
    sharedKeychain.setObject(patron, forKey: patronKey)
    
    NotificationCenter.default.post(
      name: Notification.Name.NYPLUserAccountDidChange,
      object: self
    )
  }
  
  @objc(setAdobeVendor:)
  func setAdobeVendor(_ vendor: String) {
    guard let sharedKeychain = NYPLKeychain.shared() else {
      return
    }
    
    sharedKeychain.setObject(vendor, forKey: adobeVendorKey)
    
    NotificationCenter.default.post(
      name: Notification.Name.NYPLUserAccountDidChange,
      object: self
    )
  }
  
  @objc(setAdobeToken:)
  func setAdobeToken(_ token: String) {
    guard let sharedKeychain = NYPLKeychain.shared() else {
      return
    }
    
    sharedKeychain.setObject(token, forKey: adobeTokenKey)
    
    NotificationCenter.default.post(
      name: Notification.Name.NYPLUserAccountDidChange,
      object: self
    )
  }
  
  @objc(setLicensor:)
  func setLicensor(_ licensor: [String : Any]) {
    guard let sharedKeychain = NYPLKeychain.shared() else {
      return
    }
    
    sharedKeychain.setObject(licensor, forKey: licensorKey)
  }
  
  @objc(setAuthorizationIdentifier:)
  func setAuthorizationIdentifier(_ identifier: String) {
    guard let sharedKeychain = NYPLKeychain.shared() else {
      return
    }
    
    sharedKeychain.setObject(identifier, forKey: authorizationIdentifierKey)
  }
  
  @objc(setPatron:)
  func setPatron(_ patron: [String : Any]) {
    guard let sharedKeychain = NYPLKeychain.shared() else {
      return
    }
    
    sharedKeychain.setObject(patron, forKey: patronKey)
    
    NotificationCenter.default.post(
      name: Notification.Name.NYPLUserAccountDidChange,
      object: self
    )
  }
  
  @objc(setAuthToken:)
  func setAuthToken(_ token: String) {
    guard let sharedKeychain = NYPLKeychain.shared() else {
      return
    }
    
    sharedKeychain.setObject(token, forKey: authTokenKey)
    
    NotificationCenter.default.post(
      name: Notification.Name.NYPLUserAccountDidChange,
      object: self
    )
  }
  
  @objc(setProvider:)
  func setProvider(_ provider: String) {
    guard let sharedKeychain = NYPLKeychain.shared() else {
      return
    }
    
    sharedKeychain.setObject(provider, forKey: providerKey)
    
    NotificationCenter.default.post(
      name: Notification.Name.NYPLUserAccountDidChange,
      object: self
    )
  }
  
  @objc(setUserID:)
  func setUserID(_ id: String) {
    guard let sharedKeychain = NYPLKeychain.shared() else {
      return
    }
    
    sharedKeychain.setObject(id, forKey: userIDKey)
    
    NotificationCenter.default.post(
      name: Notification.Name.NYPLUserAccountDidChange,
      object: self
    )
  }
  
  @objc(setDeviceID:)
  func setDeviceID(_ id: String) {
    guard let sharedKeychain = NYPLKeychain.shared() else {
      return
    }
    
    sharedKeychain.setObject(id, forKey: deviceIDKey)
    
    NotificationCenter.default.post(
      name: Notification.Name.NYPLUserAccountDidChange,
      object: self
    )
  }
    
  // MARK: - Remove
    
  func removeBarcodeAndPIN() {
    guard let sharedKeychain = NYPLKeychain.shared() else {
      return
    }
    
    accountInfoLock.lock()
    defer {
        accountInfoLock.unlock()
    }
    
    sharedKeychain.removeObject(forKey: barcodeKey)
    sharedKeychain.removeObject(forKey: authorizationIdentifierKey)
    sharedKeychain.removeObject(forKey: PINKey)
    
    NotificationCenter.default.post(
      name: Notification.Name.NYPLUserAccountDidChange,
      object: self
    )
  }
  
  func removeAll() {
    guard let sharedKeychain = NYPLKeychain.shared() else {
      return
    }
    
    accountInfoLock.lock()
    defer {
        accountInfoLock.unlock()
    }
    
    sharedKeychain.removeObject(forKey: adobeTokenKey)
    sharedKeychain.removeObject(forKey: patronKey)
    sharedKeychain.removeObject(forKey: authTokenKey)
    sharedKeychain.removeObject(forKey: adobeVendorKey)
    sharedKeychain.removeObject(forKey: providerKey)
    sharedKeychain.removeObject(forKey: userIDKey)
    sharedKeychain.removeObject(forKey: deviceIDKey)
    
    removeBarcodeAndPIN()
  }
}
