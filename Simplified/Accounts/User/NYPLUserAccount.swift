import UIKit

private enum StorageKey: String {
  // .barcode, .PIN, .authToken became legacy, as storage for those types was moved into .credentials enum

  case authorizationIdentifier = "NYPLAccountAuthorization"
  case barcode = "NYPLAccountBarcode" // legacy
  case PIN = "NYPLAccountPIN" // legacy
  case adobeToken = "NYPLAccountAdobeTokenKey"
  case licensor = "NYPLAccountLicensorKey"
  case patron = "NYPLAccountPatronKey"
  case authToken = "NYPLAccountAuthTokenKey" // legacy
  case authTokenRefreshUsername = "NYPLAccountAuthTokenRefreshUsernameKey"
  case authTokenRefreshPassword = "NYPLAccountAuthTokenRefreshPasswordKey"
  case adobeVendor = "NYPLAccountAdobeVendorKey"
  case provider = "NYPLAccountProviderKey"
  case userID = "NYPLAccountUserIDKey"
  case deviceID = "NYPLAccountDeviceIDKey"
  case credentials = "NYPLAccountCredentialsKey"
  case authDefinition = "NYPLAccountAuthDefinitionKey"
  case cookies = "NYPLAccountAuthCookiesKey"

  /// Generates the Keychain key for the enum case by appending the given
  /// library UUID to the enum raw value.
  func keyForLibrary(uuid libraryUUID: String?) -> String {
    guard
      // historically user data for NYPL has not used keys that contain the
      // library UUID.
      let libraryUUID = libraryUUID,
      libraryUUID != AccountsManager.shared.NYPLAccountUUID else {
        return self.rawValue
    }

    return "\(self.rawValue)_\(libraryUUID)"
  }
}

@objc protocol NYPLUserAccountProvider: NSObjectProtocol {
  var requiresUserAuthentication: Bool { get }
  
  static func sharedAccount(libraryUUID: String?) -> NYPLUserAccount
}

@objc protocol NYPLOAuthTokenSource {
  var authToken: String? { get }
  func setAuthToken(_ token: String)
  func hasOAuthClientCredentials() -> Bool
  var oauthTokenRefreshURL: URL? { get }
}


/// Represents the user account the app currently sees, be it signed in or not.
///
/// This class works as a singleton even if the initializer is not private
/// for unit tests reasons.
///
/// The way this class achieves saving credentials for multiple accounts is
/// by storing credentials on the keychain using storage keys that contain the
/// the library UUID appended after the actual key name.
/// - seealso: StorageKey.keyForLibrary(uuid:)
@objcMembers class NYPLUserAccount : NSObject, NYPLUserAccountProvider, NYPLOAuthTokenSource {
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
        StorageKey.authTokenRefreshUsername: _authTokenRefreshUsername,
        StorageKey.authTokenRefreshPassword: _authTokenRefreshPassword,

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
      return _authDefinition.read()
    }
    set {
      guard let newValue = newValue else {
        Log.debug(#function, "Attempted to write value for authDefinition but bailed because newValue was nil")
        return
      }
      Log.debug(#function, "About to write value \(newValue.authType) for authDefinition")
      _authDefinition.write(newValue)

      DispatchQueue.main.async {
        var mainFeed = URL(string: AccountsManager.shared.currentAccount?.catalogUrl ?? "")
        let resolveFn = {
          NYPLSettings.shared.accountMainFeedURL = mainFeed
          UIApplication.shared.delegate?.window??.tintColor = NYPLConfiguration.mainColor()
          NotificationCenter.default.post(name: NSNotification.Name.NYPLCurrentAccountDidChange, object: nil)
        }

        if self.needsAgeCheck {
          AccountsManager.shared.ageCheck.verifyCurrentAccountAgeRequirement(userAccountProvider: self,
                                                                             currentLibraryAccountProvider: AccountsManager.shared) { [weak self] meetsAgeRequirement in
            DispatchQueue.main.async {
              mainFeed = self?.coppaURL(isOfAge: meetsAgeRequirement)
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

  private func possibleAuths() -> [AccountDetails.Authentication] {
    let libraryAccount: Account?
    if let libraryUUID = self.libraryUUID {
      libraryAccount = AccountsManager.shared.account(libraryUUID)
    } else {
      libraryAccount = AccountsManager.shared.currentAccount
    }
    return libraryAccount?.details?.auths ?? []
  }

  func coppaURL(isOfAge: Bool) -> URL? {
    let auths = possibleAuths()
    let coppaAuth = auths.filter {
      $0.authType == .coppa
    }

    return coppaAuth.first?.coppaURL(isOfAge: isOfAge)
  }

  /// Returns the first Authentication definition available in the
  /// authentication document.
  ///
  /// - Note: This is currently used as a quick way to get the authentication
  /// definition when signed out from a library with only one authentication
  /// definition.
  ///
  /// - Important: This computed variable is here only for backward
  /// compatibility. It seems inherently wrong to choose the first definition
  /// as the default, because this will easily break for library with multiple
  /// ways to authenticate the user.
  ///
  /// - Important: DO NOT USE IN NEW CODE. If the user is signed in, simply use
  /// the `authDefinition` getter directly instead.
  var defaultAuthDefinition: AccountDetails.Authentication? {
    guard let signedInAuthDefinition = authDefinition else {
      return possibleAuths().first
    }
    return signedInAuthDefinition
  }

  /// The queue where updates to the `credentials` property happen.
  var credentialsUpdateQueue: DispatchQueue {
    return _credentials.updateQueue
  }
  
  var credentials: NYPLCredentials? {
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
      guard let newValue = newValue else {
        return
      }

      _credentials.write(newValue)

      setCrashReportingUserID(barcode)

      notifyAccountDidChange()
    }
  }

  /// At all times, this returns the current user account.
  ///
  /// - Important: Do not attempt to manually create an instance of
  /// NYPLUserAccount.
  /// - Returns: The current user account.
  @objc class func sharedAccount() -> NYPLUserAccount {
    // Note: it's important to use `currentAccountId` instead of
    // `currentAccount.uuid` because the former is immediately available
    // (being saved into the UserDefaults) while the latter is only available
    // after the app startup sequence is complete (i.e. authentication
    // document has been loaded.
    return sharedAccount(libraryUUID: AccountsManager.shared.currentAccountId)
  }

  /// CHANGES the user account singleton to work as the user account for the
  /// given library.
  ///
  /// This function is deprecated.
  ///
  /// - Important: This "getter" function has side effects. Avoid using it.
  /// - Parameter libraryUUID: The UUID of the library.
  /// - Returns: The shared NYPLUserAccount instance with its libraryUUID
  /// changed to match the one provided in input.
  class func sharedAccount(libraryUUID: String?) -> NYPLUserAccount {
    shared.accountInfoLock.lock()
    defer {
      shared.accountInfoLock.unlock()
    }

    shared.libraryUUID = libraryUUID

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
  private lazy var _authTokenRefreshUsername: NYPLKeychainVariable<String> = StorageKey.authTokenRefreshUsername
    .keyForLibrary(uuid: libraryUUID)
    .asKeychainVariable(with: accountInfoLock)
  private lazy var _authTokenRefreshPassword: NYPLKeychainVariable<String> = StorageKey.authTokenRefreshPassword
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
    }
    return false
  }
  
  func hasAuthToken() -> Bool {
    if let credentials = credentials, case NYPLCredentials.token = credentials {
      return true
    }
    return false
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

  func hasOAuthClientCredentials() -> Bool {
    return self.authDefinition?.isOauthClientCredentials ?? false
  }

  /// The URL to use to refresh the token in the OAuth Client Credentials flow.
  var oauthTokenRefreshURL: URL? {
    let oauthClientCredentialsAuth = possibleAuths().filter {
      $0.isOauthClientCredentials
    }.first
    return oauthClientCredentialsAuth?.oauthIntermediaryUrl
  }
  
  // Oauth requires login to load catalog
  var catalogRequiresAuthentication: Bool {
    return defaultAuthDefinition?.catalogRequiresAuthentication ?? false
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
    } else if hasOAuthClientCredentials() {
      return authTokenRefreshUsername
    }

    return nil
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
    } else if hasOAuthClientCredentials() {
      return authTokenRefreshPassword
    }
    return nil
  }

  var requiresUserAuthentication: Bool {
    return defaultAuthDefinition?.requiresUserAuthentication ?? false
  }

  var needsAgeCheck: Bool {
    return defaultAuthDefinition?.authType == .coppa
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
  var authTokenRefreshUsername: String? { _authTokenRefreshUsername.read() }
  var authTokenRefreshPassword: String? { _authTokenRefreshPassword.read() }

  var authToken: String? {
    if let credentials = credentials, case let NYPLCredentials.token(authToken: token) = credentials {
      return token
    }
    return nil
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
    Log.debug(#file, "About to write value for patron property")
    _patron.write(patron)
    notifyAccountDidChange()
  }


  /// Saves the OAuth token in the keychain, for both the regular OAuth flow
  /// (e.g. for Clever) and the Client Credentials flow.
  ///
  /// - Important: For OAuth Client Credentials flow, it is required to save
  /// to call `setRefreshTokenInfo(username:password:)` before calling
  /// `setAuthToken:`.
  /// - Parameter token: The new OAuth token.
  @objc(setAuthToken:)
  func setAuthToken(_ token: String) {
    Log.debug(#function, "authType=\(String(describing: authDefinition?.authType)) authToken=\(token)")

    // this check is required because in the client credentials flow we need
    // to save both the username/password and authtoken. However, during
    // sign-in, when we save the OAuth token this triggers an accountDidChange
    // notification (set `credentials` setter) which then triggers a nil-out
    // of the username and password on the UI, which then makes it impossible
    // to save username and password. For this reason we require to save
    // the refresh username and password *before* saving the authToken.
    if !hasOAuthClientCredentials() || authTokenRefreshUsername != nil {
      Log.debug(#function, "About to write credentials for authToken...")
      credentials = .token(authToken: token)
    }
  }

  func setRefreshTokenInfo(username: String, password: String) {
    _authTokenRefreshUsername.write(username)
    _authTokenRefreshPassword.write(password)
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

  private func setCrashReportingUserID(_ userID: String?) {
    // make sure to set the barcode related to the current account (aka library)
    // not the one we just signed in to, because we could have signed in into
    // library A, but still browsing the catalog of library B.
    if libraryUUID == AccountsManager.shared.currentAccountId {
      NYPLErrorLogger.setUserID(userID)
    }
  }

  // MARK: - Remove

  func removeAll() {
    setCrashReportingUserID(nil)
    keychainTransaction.perform {
      _adobeToken.write(nil)
      _patron.write(nil)
      _adobeVendor.write(nil)
      _provider.write(nil)
      _userID.write(nil)
      _deviceID.write(nil)

      keychainTransaction.perform {
        _authDefinition.write(nil)
        Log.debug(#function, "authDefinition after removing value: \(String(describing: _authDefinition.read()?.authType))")
        _credentials.write(nil)
        _cookies.write(nil)
        _authorizationIdentifier.write(nil)
        _authTokenRefreshUsername.write(nil)
        _authTokenRefreshPassword.write(nil)

        // remove legacy, just in case
        _barcode.write(nil)
        _pin.write(nil)
        _authToken.write(nil)

        notifyAccountDidChange()

        NotificationCenter.default.post(name: Notification.Name.NYPLDidSignOut,
                                        object: nil)
      }
    }
  }
}

extension NYPLUserAccount: NYPLSignedInStateProvider {
  func isSignedIn() -> Bool {
    return hasCredentials()
  }
}

extension NYPLUserAccount: NYPLBasicAuthCredentialsProvider {
  var username: String? {
    return barcode
  }

  var pin: String? {
    return PIN
  }
}

