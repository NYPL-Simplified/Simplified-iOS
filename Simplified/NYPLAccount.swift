import Foundation

let NYPLAccountDidChangeNotification = "NYPLAccountDidChangeNotification"
let NYPLAccountLoginDidChangeNotification = "NYPLAccountLoginDidChangeNotification"

@objcMembers class NYPLAccountSwift : NSObject {
  static private var shared = NYPLAccountSwift()
    
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

  @objc class func sharedAccount() -> NYPLAccountSwift
  {
    return sharedAccount(libraryUUID: AccountsManager.shared.currentAccount?.uuid)
  }
    
  @objc(sharedAccount:)
  class func sharedAccount(libraryUUID: String?) -> NYPLAccountSwift
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
      
  }
    
  @objc(setAdobeToken:patron:)
  func setAdobeToken(token: String, patron: [String : Any]) {
      
  }
  
  @objc(setAdobeVender:)
  func setAdobeVender(vendor: String) {
      
  }
  
  @objc(setAdobeToken:)
  func setAdobeToken(token: String) {
      
  }
  
  @objc(setLicensor:)
  func setLicensor(licensor: [String : Any]) {
      
  }
  
  @objc(setAuthorizationIdentifier:)
  func setAuthorizationIdentifier(identifier: String) {
      
  }
  
  @objc(setPatron:)
  func setPatron(patron: [String : Any]) {
      
  }
  
  @objc(setAuthToken:)
  func setAuthToken(token: String) {
      
  }
  
  @objc(setProvider:)
  func setProvider(provider: String) {
      
  }
  
  @objc(setUserID:)
  func setUserID(id: String) {
      
  }
  
  @objc(setDeviceID:)
  func setDeviceID(id: String) {
      
  }
    
  // MARK: - Remove
    
  func removeBarcodeAndPIN() {
      
  }
  
  func removeAll() {
      
  }
}
