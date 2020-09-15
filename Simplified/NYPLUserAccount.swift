import Foundation

private enum StorageKey: String {
  // .barcode, .PIN, .authToken became legacy, as storage for those types was moved into .credentials enum

  case authorizationIdentifier = "NYPLAccountAuthorization"
  case barcode = "NYPLAccountBarcode" // legacy
  case PIN = "NYPLAccountPIN" // legacy
  case adobeToken = "NYPLAccountAdobeTokenKey"
  case licensor = "NYPLAccountLicensorKey"
  case patron = "NYPLAccountPatronKey"
  case authToken = "NYPLAccountAuthTokenKey" // legacy
  case adobeVendor = "NYPLAccountAdobeVendorKey"
  case provider = "NYPLAccountProviderKey"
  case userID = "NYPLAccountUserIDKey"
  case deviceID = "NYPLAccountDeviceIDKey"
  case credentials = "NYPLAccountCredentialsKey"
  case authDefinition = "NYPLAccountAuthDefinitionKey"
  case cookies = "NYPLAccountAuthCookiesKey"

  func keyForLibrary(uuid libraryUUID: String?) -> String {
    guard let libraryUUID = libraryUUID else { return self.rawValue }
    return "\(self.rawValue)_\(libraryUUID)"
  }
}

@objcMembers class NYPLUserAccount : NSObject {
  static private let shared = NYPLUserAccount()
  private let accountInfoLock = NSRecursiveLock()
  private lazy var keychainTransaction = NYPLKeychainVariableTransaction(accountInfoLock: accountInfoLock)
    
  private var libraryUUID: String? {
    didSet {
      guard libraryUUID != oldValue else { return }
      let variables: [StorageKey: Keyable] = [
        StorageKey.authorizationIdentifier: _authorizationIdentifier,
        StorageKey.adobeToken: _adobeToken,
        StorageKey.licensor: _licensor,
        StorageKey.patron: _patron,
        StorageKey.adobeVendor: _adobeVendor,
        StorageKey.provider: _provider,
        StorageKey.userID: _userID,
        StorageKey.deviceID: _deviceID,
        StorageKey.credentials: _credentials,
        StorageKey.authDefinition: _authDefinition,
        StorageKey.cookies: _cookies,

        // legacy
        StorageKey.barcode: _barcode,
        StorageKey.PIN: _pin,
        StorageKey.authToken: _authToken,
      ]

      for (key, var value) in variables {
        value.key = key.keyForLibrary(uuid: libraryUUID)
      }
    }
  }

  var authDefinition: AccountDetails.Authentication? {
    get {
      let legacyDefinition: AccountDetails.Authentication?
      if let libraryUUID = self.libraryUUID {
        legacyDefinition = AccountsManager.shared.account(libraryUUID)?.details?.auths.first
      } else {
        legacyDefinition = AccountsManager.shared.currentAccount?.details?.auths.first
      }
      return _authDefinition.read() ?? legacyDefinition
    }
    set {
      guard let newValue = newValue else { return }
      _authDefinition.write(newValue)

      DispatchQueue.main.async {
        var mainFeed = URL(string: AccountsManager.shared.currentAccount?.catalogUrl ?? "")
        let resolveFn = {
          NYPLSettings.shared.accountMainFeedURL = mainFeed
          UIApplication.shared.delegate?.window??.tintColor = NYPLConfiguration.mainColor()
          NotificationCenter.default.post(name: NSNotification.Name.NYPLCurrentAccountDidChange, object: nil)
        }

        if self.needsAgeCheck {
          NYPLAgeCheck.shared().verifyCurrentAccountAgeRequirement { [weak self] meetsAgeRequirement in
            DispatchQueue.main.async {
              mainFeed = self?.authDefinition?.coppaURL(isOfAge: meetsAgeRequirement)
              resolveFn()
            }
          }
        } else {
          resolveFn()
        }
      }

      notifyAccountDidChange()
    }
  }

  public private(set) var credentials: NYPLCredentials? {
    get {
      var credentials = _credentials.read()

      if credentials == nil {
        // if there are no credentials in memory, try to migrate from legacy storage keys
        if let barcode = legacyBarcode, let pin = legacyPin {
          // barcode and pin was used previously
          credentials = .barcodeAndPin(barcode: barcode, pin: pin)

          // remove legacy storage and save into new place
          keychainTransaction.perform {
            _credentials.write(credentials)
            _barcode.write(nil)
            _pin.write(nil)
          }
        } else if let authToken = legacyAuthToken {
          // auth token was used previously
          credentials = .token(authToken: authToken)

          // remove legacy storage and save into new place
          keychainTransaction.perform {
            _credentials.write(credentials)
            _authToken.write(nil)
          }
        }
      }

      return credentials
    }
    set {
      guard let newValue = newValue else { return }

      _credentials.write(newValue)

      // make sure to set the barcode related to the current account (aka library)
      // not the one we just signed in to, because we could have signed in into
      // library A, but still browsing the catalog of library B.
      if case let .barcodeAndPin(barcode: userBarcode, pin: _) = newValue {
        NYPLErrorLogger.setUserID(userBarcode)
      }

      notifyAccountDidChange()
    }
  }

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
    if let uuid = libraryUUID, uuid != AccountsManager.NYPLAccountUUID {
      shared.libraryUUID = uuid
    } else {
      shared.libraryUUID = nil
    }

    return shared
  }

  private func notifyAccountDidChange() {
    NotificationCenter.default.post(
      name: Notification.Name.NYPLUserAccountDidChange,
      object: self
    )
  }

  // MARK: - Storage
  private lazy var _authorizationIdentifier: NYPLKeychainVariable<String> = StorageKey.authorizationIdentifier
    .keyForLibrary(uuid: libraryUUID)
    .asKeychainVariable(with: accountInfoLock)
  private lazy var _adobeToken: NYPLKeychainVariable<String> = StorageKey.adobeToken
    .keyForLibrary(uuid: libraryUUID)
    .asKeychainVariable(with: accountInfoLock)
  private lazy var _licensor: NYPLKeychainVariable<[String:Any]> = StorageKey.licensor
    .keyForLibrary(uuid: libraryUUID)
    .asKeychainVariable(with: accountInfoLock)
  private lazy var _patron: NYPLKeychainVariable<[String:Any]> = StorageKey.patron
    .keyForLibrary(uuid: libraryUUID)
    .asKeychainVariable(with: accountInfoLock)
  private lazy var _adobeVendor: NYPLKeychainVariable<String> = StorageKey.adobeVendor
    .keyForLibrary(uuid: libraryUUID)
    .asKeychainVariable(with: accountInfoLock)
  private lazy var _provider: NYPLKeychainVariable<String> = StorageKey.provider
    .keyForLibrary(uuid: libraryUUID)
    .asKeychainVariable(with: accountInfoLock)
  private lazy var _userID: NYPLKeychainVariable<String> = StorageKey.userID
    .keyForLibrary(uuid: libraryUUID)
    .asKeychainVariable(with: accountInfoLock)
  private lazy var _deviceID: NYPLKeychainVariable<String> = StorageKey.deviceID
    .keyForLibrary(uuid: libraryUUID)
    .asKeychainVariable(with: accountInfoLock)
  private lazy var _credentials: NYPLKeychainCodableVariable<NYPLCredentials> = StorageKey.credentials
    .keyForLibrary(uuid: libraryUUID)
    .asKeychainCodableVariable(with: accountInfoLock)
  private lazy var _authDefinition: NYPLKeychainCodableVariable<AccountDetails.Authentication> = StorageKey.authDefinition
    .keyForLibrary(uuid: libraryUUID)
    .asKeychainCodableVariable(with: accountInfoLock)
  private lazy var _cookies: NYPLKeychainVariable<[HTTPCookie]> = StorageKey.cookies
    .keyForLibrary(uuid: libraryUUID)
    .asKeychainVariable(with: accountInfoLock)

  // Legacy
  private lazy var _barcode: NYPLKeychainVariable<String> = StorageKey.barcode
    .keyForLibrary(uuid: libraryUUID)
    .asKeychainVariable(with: accountInfoLock)
  private lazy var _pin: NYPLKeychainVariable<String> = StorageKey.PIN
    .keyForLibrary(uuid: libraryUUID)
    .asKeychainVariable(with: accountInfoLock)
  private lazy var _authToken: NYPLKeychainVariable<String> = StorageKey.authToken
    .keyForLibrary(uuid: libraryUUID)
    .asKeychainVariable(with: accountInfoLock)

  // MARK: - Check
    
  func hasBarcodeAndPIN() -> Bool {
    if let credentials = credentials, case NYPLCredentials.barcodeAndPin = credentials {
      return true
    } else {
      return false
    }
  }
  
  func hasAuthToken() -> Bool {
    if let credentials = credentials, case NYPLCredentials.token = credentials {
      return true
    } else {
      return false
    }
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

  // Oauth requires login to load catalog
  var isCatalogSecured: Bool {
    return authDefinition?.isCatalogSecured ?? false
  }

  // MARK: - Legacy
  
  private var legacyBarcode: String? { return _barcode.read() }
  private var legacyPin: String? { return _pin.read() }
  var legacyAuthToken: String? { _authToken.read() }

  // MARK: - GET

  /// The barcode of this user; for NYPL, this is either an actual barcode
  /// or a username.
  /// You should be able to use either one as authentication with the
  /// circulation manager and platform.nypl.org, because they both pass auth
  /// information to the ILS, which is the source of truth. The ILS will
  /// validate credentials the same whether the patron identifier is a
  /// username or one of their barcodes. However, it's possible that some
  /// features of platform.nypl.org will work if you give them a 14-digit
  /// barcode but not a 7-letter username or a 16-digit NYC ID.
  var barcode: String? {
    if let credentials = credentials, case let NYPLCredentials.barcodeAndPin(barcode: barcode, pin: _) = credentials {
      return barcode
    } else {
      return nil
    }
  }

  /// For any library but the NYPL, this identifier can be anything they want.
  ///
  /// For NYPL, this is *a* barcode, either a 14-digit NYPL-issued barcode, or
  /// a 16-digit "NYC ID" barcode issued by New York City. It's in fact
  /// possible for NYC residents to get a NYC ID and set that up **as a**
  /// NYPL barcode, even if they already have a NYPL card. We use
  /// authorization_identifier to mean the "number that's probably on the
  ///  piece of plastic the patron uses as their library card".
  /// - Note: A patron can have multiple barcodes, because patrons may lose
  /// their library card and get a new one with a different barcode.
  /// Authenticating with any of those barcodes should work.
  /// - Note: This is NOT the unique ILS ID. That's internal-only and it's not
  /// exposed to the public.
  var authorizationIdentifier: String? { _authorizationIdentifier.read() }

  var PIN: String? {
    if let credentials = credentials, case let NYPLCredentials.barcodeAndPin(barcode: _, pin: pin) = credentials {
      return pin
    } else {
      return nil
    }
  }

  var needsAuth:Bool {
    let authType = authDefinition?.authType ?? .none
    return authType == .basic || authType == .oauthIntermediary || authType == .saml
  }

  var needsAgeCheck:Bool {
    let authType = authDefinition?.authType ?? .none
    return authType == .coppa
  }

  var deviceID: String? { _deviceID.read() }
  /// The user ID to use with Adobe DRM.
  var userID: String? { _userID.read() }
  var adobeVendor: String? { _adobeVendor.read() }
  var provider: String? { _provider.read() }
  var patron: [String:Any]? { _patron.read() }
  var adobeToken: String? { _adobeToken.read() }
  var licensor: [String:Any]? { _licensor.read() }
  var cookies: [HTTPCookie]? { _cookies.read() }

  var authToken: String? {
    if let credentials = credentials, case let NYPLCredentials.token(authToken: token) = credentials {
      return token
    } else {
      return nil
    }
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



  // MARK: - SET
  @objc(setBarcode:PIN:)
  func setBarcode(_ barcode: String, PIN: String) {
    credentials = .barcodeAndPin(barcode: barcode, pin: PIN)
  }
    
  @objc(setAdobeToken:patron:)
  func setAdobeToken(_ token: String, patron: [String : Any]) {
    keychainTransaction.perform {
      _adobeToken.write(token)
      _patron.write(patron)
    }

    notifyAccountDidChange()
  }
  
  @objc(setAdobeVendor:)
  func setAdobeVendor(_ vendor: String) {
    _adobeVendor.write(vendor)
    notifyAccountDidChange()
  }
  
  @objc(setAdobeToken:)
  func setAdobeToken(_ token: String) {
    _adobeToken.write(token)
    notifyAccountDidChange()
  }
  
  @objc(setLicensor:)
  func setLicensor(_ licensor: [String : Any]) {
    _licensor.write(licensor)
  }

  /// This authorization identifier is returned by the circulation manager
  /// upon successful sign-in.
  /// - parameter identifier: For NYPL, this can either be
  /// a 14-digit NYPL-issued barcode, or a 16-digit "NYC ID"
  /// barcode issued by New York City. For other libraries,
  /// this can be any string they want.
  @objc(setAuthorizationIdentifier:)
  func setAuthorizationIdentifier(_ identifier: String) {
    _authorizationIdentifier.write(identifier)
  }
  
  @objc(setPatron:)
  func setPatron(_ patron: [String : Any]) {
    _patron.write(patron)
    notifyAccountDidChange()
  }
  
  @objc(setAuthToken:)
  func setAuthToken(_ token: String) {
    credentials = .token(authToken: token)
  }

  @objc(setCookies:)
  func setCookies(_ cookies: [HTTPCookie]) {
    _cookies.write(cookies)
    notifyAccountDidChange()
  }

  @objc(setProvider:)
  func setProvider(_ provider: String) {
    _provider.write(provider)
    notifyAccountDidChange()
  }

  /// - parameter id: The user ID to use for Adobe DRM.
  @objc(setUserID:)
  func setUserID(_ id: String) {
    _userID.write(id)
    notifyAccountDidChange()
  }
  
  @objc(setDeviceID:)
  func setDeviceID(_ id: String) {
    _deviceID.write(id)
    notifyAccountDidChange()
  }
    
  // MARK: - Remove
  func removeBarcodeAndPIN() {
    keychainTransaction.perform {
      _authDefinition.write(nil)
      _credentials.write(nil)
      _cookies.write(nil)
      _authorizationIdentifier.write(nil)

      // remove legacy, just in case
      _barcode.write(nil)
      _pin.write(nil)
      _authToken.write(nil)

      notifyAccountDidChange()

      NotificationCenter.default.post(name: Notification.Name.NYPLDidSignOut,
                                      object: nil)
    }
  }

  func removeAll() {
    keychainTransaction.perform {
      _adobeToken.write(nil)
      _patron.write(nil)
      _adobeVendor.write(nil)
      _provider.write(nil)
      _userID.write(nil)
      _deviceID.write(nil)

      removeBarcodeAndPIN()
    }
  }
}

extension NYPLUserAccount: NYPLSignedInStateProvider {
  func isSignedIn() -> Bool {
    return hasBarcodeAndPIN()
  }
}
