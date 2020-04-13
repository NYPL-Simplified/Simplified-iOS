import Foundation

@objcMembers class NYPLAccount : NSObject {
  static private let shared = NYPLAccount()
    
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

  @objc class func sharedAccount() -> NYPLAccount
  {
    return sharedAccount(libraryUUID: AccountsManager.shared.currentAccount?.uuid)
  }
    
  @objc(sharedAccount:)
  class func sharedAccount(libraryUUID: String?) -> NYPLAccount
  {
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
    return NYPLKeychain.shared()?.object(forKey: barcodeKey) as? String ?? nil
  }
    
  var authorizationIdentifier: String? {
    return NYPLKeychain.shared()?.object(forKey: authorizationIdentifierKey) as? String ?? nil
  }
  
  var PIN: String? {
    return NYPLKeychain.shared()?.object(forKey: PINKey) as? String ?? nil
  }
  
  var deviceID: String? {
    return NYPLKeychain.shared()?.object(forKey: deviceIDKey) as? String ?? nil
  }
  
  var userID: String? {
    return NYPLKeychain.shared()?.object(forKey: userIDKey) as? String ?? nil
  }
    
  var adobeVendor: String? {
    return NYPLKeychain.shared()?.object(forKey: adobeVendorKey) as? String ?? nil
  }
    
  var provider: String? {
    return NYPLKeychain.shared()?.object(forKey: providerKey) as? String ?? nil
  }
    
  var patron: [String:Any]? {
    return NYPLKeychain.shared()?.object(forKey: patronKey) as? [String:Any] ?? nil
  }
    
  var patronFullName: String? {
    if let patron = patron,
      let name = patron["name"] as? [String:String],
      let first = name["first"],
      let middle = name["middle"],
      let last = name["last"]
    {
      return "\(first) \(middle) \(last)"
    }
    return nil
  }
    
  var authToken: String? {
    return NYPLKeychain.shared()?.object(forKey: authTokenKey) as? String ?? nil
  }
    
  var adobeToken: String? {
    return NYPLKeychain.shared()?.object(forKey: adobeTokenKey) as? String ?? nil
  }
    
  var licensor: [String:Any]? {
    return NYPLKeychain.shared()?.object(forKey: licensorKey) as? [String:Any] ?? nil
  }
    
  // MARK: - SET
    
  @objc(setBarcode:PIN:)
  func setBarcode(barcode: String, PIN: String) {
    guard let sharedKeychain = NYPLKeychain.shared() else {
      return
    }
    
    sharedKeychain.setObject(barcode, forKey: barcodeKey)
    sharedKeychain.setObject(PIN, forKey: PINKey)
    
    // make sure to set the barcode related to the current account (aka library)
    // not the one we just signed in to, because we could have signed in into
    // library A, but still browsing the catalog of library B.
    NYPLErrorLogger.setUserID(NYPLAccount.sharedAccount().barcode)
    
    NotificationCenter.default.post(
      name: Notification.Name.NYPLAccountDidChange,
      object: self
    )
  }
    
  @objc(setAdobeToken:patron:)
  func setAdobeToken(token: String, patron: [String : Any]) {
    guard let sharedKeychain = NYPLKeychain.shared() else {
      return
    }
    
    sharedKeychain.setObject(token, forKey: adobeTokenKey)
    sharedKeychain.setObject(patron, forKey: patronKey)
    
    NotificationCenter.default.post(
      name: Notification.Name.NYPLAccountDidChange,
      object: self
    )
  }
  
  @objc(setAdobeVender:)
  func setAdobeVender(vendor: String) {
    guard let sharedKeychain = NYPLKeychain.shared() else {
      return
    }
    
    sharedKeychain.setObject(vendor, forKey: adobeVendorKey)
    
    NotificationCenter.default.post(
      name: Notification.Name.NYPLAccountDidChange,
      object: self
    )
  }
  
  @objc(setAdobeToken:)
  func setAdobeToken(token: String) {
    guard let sharedKeychain = NYPLKeychain.shared() else {
      return
    }
    
    sharedKeychain.setObject(token, forKey: adobeTokenKey)
    
    NotificationCenter.default.post(
      name: Notification.Name.NYPLAccountDidChange,
      object: self
    )
  }
  
  @objc(setLicensor:)
  func setLicensor(licensor: [String : Any]) {
    guard let sharedKeychain = NYPLKeychain.shared() else {
      return
    }
    
    sharedKeychain.setObject(licensor, forKey: licensorKey)
  }
  
  @objc(setAuthorizationIdentifier:)
  func setAuthorizationIdentifier(identifier: String) {
    guard let sharedKeychain = NYPLKeychain.shared() else {
      return
    }
    
    sharedKeychain.setObject(identifier, forKey: authorizationIdentifierKey)
  }
  
  @objc(setPatron:)
  func setPatron(patron: [String : Any]) {
    guard let sharedKeychain = NYPLKeychain.shared() else {
      return
    }
    
    sharedKeychain.setObject(patron, forKey: patronKey)
    
    NotificationCenter.default.post(
      name: Notification.Name.NYPLAccountDidChange,
      object: self
    )
  }
  
  @objc(setAuthToken:)
  func setAuthToken(token: String) {
    guard let sharedKeychain = NYPLKeychain.shared() else {
      return
    }
    
    sharedKeychain.setObject(token, forKey: authTokenKey)
    
    NotificationCenter.default.post(
      name: Notification.Name.NYPLAccountDidChange,
      object: self
    )
  }
  
  @objc(setProvider:)
  func setProvider(provider: String) {
    guard let sharedKeychain = NYPLKeychain.shared() else {
      return
    }
    
    sharedKeychain.setObject(provider, forKey: providerKey)
    
    NotificationCenter.default.post(
      name: Notification.Name.NYPLAccountDidChange,
      object: self
    )
  }
  
  @objc(setUserID:)
  func setUserID(id: String) {
    guard let sharedKeychain = NYPLKeychain.shared() else {
      return
    }
    
    sharedKeychain.setObject(id, forKey: userIDKey)
    
    NotificationCenter.default.post(
      name: Notification.Name.NYPLAccountDidChange,
      object: self
    )
  }
  
  @objc(setDeviceID:)
  func setDeviceID(id: String) {
    guard let sharedKeychain = NYPLKeychain.shared() else {
      return
    }
    
    sharedKeychain.setObject(id, forKey: deviceIDKey)
    
    NotificationCenter.default.post(
      name: Notification.Name.NYPLAccountDidChange,
      object: self
    )
  }
    
  // MARK: - Remove
    
  func removeBarcodeAndPIN() {
    guard let sharedKeychain = NYPLKeychain.shared() else {
      return
    }
    
    sharedKeychain.removeObject(forKey: barcodeKey)
    sharedKeychain.removeObject(forKey: authorizationIdentifierKey)
    sharedKeychain.removeObject(forKey: PINKey)
    
    NotificationCenter.default.post(
      name: Notification.Name.NYPLAccountDidChange,
      object: self
    )
  }
  
  func removeAll() {
    guard let sharedKeychain = NYPLKeychain.shared() else {
      return
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
