//
//  NYPLSignInBusinessLogic.swift
//  Simplified
//
//  Created by Ettore Pasquini on 5/5/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import UIKit
import NYPLCardCreator

@objc enum NYPLAuthRequestType: Int {
  case signIn = 1
  case signOut = 2
}

@objc protocol NYPLBookRegistrySyncing: NSObjectProtocol {
  var syncing: Bool {get}
  func reset(_ libraryAccountUUID: String)
  func syncResettingCache(_ resetCache: Bool,
                          completionHandler: ((_ success: Bool) -> Void)?)
  func save()
}

@objc protocol NYPLDRMAuthorizing: NSObjectProtocol {
  var workflowsInProgress: Bool {get}
}

@objc protocol NYPLLogOutExecutor: NSObjectProtocol {
  func performLogOut()
}

#if FEATURE_DRM_CONNECTOR
extension NYPLADEPT: NYPLDRMAuthorizing {}
#endif
extension NYPLBookRegistry: NYPLBookRegistrySyncing {}

@objcMembers
class NYPLSignInBusinessLogic: NSObject, NYPLSignedInStateProvider {

  let libraryAccountID: String
  private let permissionsCheckLock = NSLock()
  let requestTimeoutInterval: TimeInterval = 25.0

  private let juvenileAuthLock = NSLock()
  @objc private(set) var juvenileAuthIsOngoing = false
  private var juvenileCardCreationCoordinator: JuvenileFlowCoordinator?

  private let libraryAccountsProvider: NYPLLibraryAccountsProvider
  let universalLinksSettings: NYPLUniversalLinksSettings
  private let bookRegistry: NYPLBookRegistrySyncing

  /// Provides the user account for a given library.
  private let userAccountProvider: NYPLUserAccountProvider.Type

  weak private var drmAuthorizer: NYPLDRMAuthorizing?

  /// The primary way for the business logic to communicate with the UI.
  weak var uiDelegate: NYPLSignInBusinessLogicUIDelegate?

  @objc init(libraryAccountID: String,
             libraryAccountsProvider: NYPLLibraryAccountsProvider,
             universalLinksSettings: NYPLUniversalLinksSettings,
             bookRegistry: NYPLBookRegistrySyncing,
             userAccountProvider: NYPLUserAccountProvider.Type,
             uiDelegate: NYPLSignInBusinessLogicUIDelegate?,
             drmAuthorizer: NYPLDRMAuthorizing?) {
    self.uiDelegate = uiDelegate
    self.libraryAccountID = libraryAccountID
    self.libraryAccountsProvider = libraryAccountsProvider
    self.universalLinksSettings = universalLinksSettings
    self.bookRegistry = bookRegistry
    self.userAccountProvider = userAccountProvider
    self.drmAuthorizer = drmAuthorizer
    super.init()
  }

  @objc var libraryAccount: Account? {
    return libraryAccountsProvider.account(libraryAccountID)
  }

  var selectedIDP: OPDS2SamlIDP?

  /// This overrides the sign in state logic to behave as if user isn't
  /// authenticated. This is useful if we already have credentials, but
  /// the session expired (e.g. SAML flow).
  var ignoreSignedInState: Bool = false

  private var _selectedAuthentication: AccountDetails.Authentication?
  var selectedAuthentication: AccountDetails.Authentication? {
    get {
      guard _selectedAuthentication == nil else { return _selectedAuthentication }
      guard userAccount.authDefinition == nil else { return userAccount.authDefinition }
      guard let auths = libraryAccount?.details?.auths else { return nil }
      guard auths.count > 1 else { return auths.first }

      return nil
    }
    set {
      _selectedAuthentication = newValue
    }
  }

  /// Creates a request object for signing in or out, depending on
  /// on which authentication mechanism is currently selected.
  /// - Parameters:
  ///   - authType: What kind of authentication request should be created.
  ///   - context: A string for further context for error reporting.
  /// - Returns: A request for signing in or signing out.
  @objc func makeRequest(for authType: NYPLAuthRequestType,
                         context: String) -> URLRequest? {

    let authTypeStr = (authType == .signOut ? "signing out" : "signing in")

    guard
      let urlStr = libraryAccount?.details?.userProfileUrl,
      let url = URL(string: urlStr) else {
        NYPLErrorLogger.logError(withCode: .noURL,
                                 summary: "Error \(authTypeStr)",
                                 message: "Unable to create URL for \(authTypeStr)",
                                 metadata: nil)
        return nil
    }

    var req = URLRequest(url: url)
    req.timeoutInterval = requestTimeoutInterval

    if let selectedAuth = selectedAuthentication,
      (selectedAuth.isOauth || selectedAuth.isSaml) {

      if let uiDelegate = uiDelegate, let authToken = uiDelegate.authToken {
        // Note: this is officially unsupported by the URL loading system
        // in iOS but it does work. It is necessary because the officially
        // supported method of providing authorization info to a request is via
        // `URLAuthenticationChallenge`, which has no api for Bearer token
        // authentication. Basic auth via username + password works fine with
        // challenges (see `NYPLSettingsAccountURLSessionChallengeHandler`).
        let authorization = "Bearer \(authToken)"
        req.addValue(authorization, forHTTPHeaderField: "Authorization")
      } else {
        Log.info(#file, "Auth token expected, but none is available.")
        NYPLErrorLogger.logError(withCode: .validationWithoutAuthToken,
                                 summary: "Error \(authTypeStr)",
                                 message: "There is no token available during oauth/saml authentication validation.",
                                 metadata: [
                                  "isSAML": selectedAuth.isSaml,
                                  "isOAuth": selectedAuth.isOauth,
                                  "context": context,
                                  "uiDelegate nil?": uiDelegate == nil ? "y" : "n"])
      }
    }

    return req
  }

  /// The user account for the library we are signing in to.
  var userAccount: NYPLUserAccount {
    return userAccountProvider.sharedAccount(libraryUUID: libraryAccountID)
  }

  /// Updates the user account for the library we are signing in to.
  /// - Parameters:
  ///   - barcode: The new barcode, if available.
  ///   - pin: The new PIN, if barcode is provided.
  ///   - authToken: the token if `selectedAuthentication` is OAuth or SAML. 
  ///   - patron: The patron info for OAuth / SAML authentication.
  ///   - cookies: Cookies for SAML authentication.
  func updateUserAccount(withBarcode barcode: String?,
                         pin: String?,
                         authToken: String?,
                         patron: [String:Any]?,
                         cookies: [HTTPCookie]?) {

    if let selectedAuthentication = selectedAuthentication {
      if selectedAuthentication.isOauth || selectedAuthentication.isSaml {
        if let authToken = authToken {
          userAccount.setAuthToken(authToken)
        }
        if let patron = patron {
          userAccount.setPatron(patron)
        }
      } else {
        setBarcode(barcode, pin: pin)
      }

      if selectedAuthentication.isSaml {
        if let cookies = cookies {
          userAccount.setCookies(cookies)
        }
      }
    } else {
      setBarcode(barcode, pin: pin)
    }

    userAccount.authDefinition = selectedAuthentication

    if libraryAccountID == libraryAccountsProvider.currentAccountId {
      bookRegistry.syncResettingCache(false) { [weak bookRegistry] success in
        if success {
          bookRegistry?.save()
        }
      }
    }

    NotificationCenter.default.post(name: .NYPLIsSigningIn, object: false)
  }

  func setBarcode(_ barcode: String?, pin: String?) {
    if let barcode = barcode, let pin = pin {
      userAccount.setBarcode(barcode, PIN:pin)
    }
  }

  func librarySupportsBarcodeDisplay() -> Bool {
    // For now, only supports libraries granted access in Accounts.json,
    // is signed in, and has an authorization ID returned from the loans feed.
    return userAccount.hasBarcodeAndPIN() &&
      userAccount.authorizationIdentifier != nil &&
      (selectedAuthentication?.supportsBarcodeDisplay ?? false)
  }

  func isSignedIn() -> Bool {
    if ignoreSignedInState {
      return false
    }
    return userAccount.hasCredentials()
  }

  func registrationIsPossible() -> Bool {
    return !isSignedIn() && NYPLConfiguration.cardCreationEnabled() && libraryAccount?.details?.signUpUrl != nil
  }

  func isSamlPossible() -> Bool {
    libraryAccount?.details?.auths.contains { $0.isSaml } ?? false
  }

  @objc func juvenileCardsManagementIsPossible() -> Bool {
    guard NYPLConfiguration.cardCreationEnabled() else {
      return false
    }
    guard libraryAccount?.details?.supportsCardCreator ?? false else {
      return false
    }
    guard libraryAccountID == libraryAccountsProvider.NYPLAccountUUID else {
      return false
    }

    return isSignedIn()
  }

  @objc func shouldShowEULALink() -> Bool {
    return libraryAccount?.details?.getLicenseURL(.eula) != nil
  }

  @objc func shouldShowSyncButton() -> Bool {
    guard let libraryDetails = libraryAccount?.details else {
      return false
    }

    return libraryDetails.supportsSimplyESync &&
      libraryDetails.getLicenseURL(.annotations) != nil &&
      userAccount.hasCredentials() &&
      libraryAccountID == libraryAccountsProvider.currentAccount?.uuid
  }

  /// Updates server sync setting for the currently selected library.
  /// - Parameters:
  ///   - granted: Whether the user is granting sync permission or not.
  ///   - postServerSyncCompletion: Only run when granting sync permission.
  @objc func changeSyncPermission(to granted: Bool,
                                  postServerSyncCompletion: @escaping (Bool) -> Void) {
    if granted {
      // When granting, attempt to enable on the server.
      NYPLAnnotations.updateServerSyncSetting(toEnabled: true) { success in
        self.libraryAccount?.details?.syncPermissionGranted = success
        postServerSyncCompletion(success)
      }
    } else {
      // When revoking, just ignore the server's annotations.
      libraryAccount?.details?.syncPermissionGranted = false
    }
  }

  /// Checks with the annotations sync status with the server, adding logic
  /// to make sure only one such requests is being executed at a time.
  /// - Parameters:
  ///   - preWork: Any preparatory work to be done. This block is run
  ///   synchronously on the main thread. It's not run at all if a request is
  ///   already ongoing or if the current library doesn't support syncing.
  ///   - postWork: Any final work to be done. This block is run
  ///   on the main thread. It's not run at all if a request is
  ///   already ongoing or if the current library doesn't support syncing.
  @objc func checkSyncPermission(preWork: () -> Void,
                                 postWork: @escaping (_ enableSync: Bool) -> Void) {
    guard let libraryDetails = libraryAccount?.details else {
      return
    }

    guard permissionsCheckLock.try(), libraryDetails.supportsSimplyESync else {
      Log.debug(#file, "Skipping sync setting check. Request already in progress or sync not supported.")
      return
    }

    NYPLMainThreadRun.sync {
      preWork()
    }

    NYPLAnnotations.requestServerSyncStatus(forAccount: userAccount) { enableSync in
      if enableSync {
        libraryDetails.syncPermissionGranted = true
      }

      NYPLMainThreadRun.sync {
        postWork(enableSync)
      }

      self.permissionsCheckLock.unlock()
    }
  }

  // MARK: - Card Creation

  private func cardCreatorCredentials() -> (username: String, password: String) {
    // the likeliness of this username/password to be nil is close to zero
    // because these strings are decoded from static byte arrays. So any error
    // should be detected during QA. Even in the case where these are nil, by
    // using the "" default for initializing the CardCreatorConfiguration (see
    // below) we'll run into an error soon after, at the 1st screen of the flow.
    if NYPLSecrets.cardCreatorUsername == nil {
      NYPLErrorLogger.logError(withCode: NYPLErrorCode.cardCreatorCredentialsDecodeFail,
                               summary: "CardCreator username decode error from NYPLSecrets")
    }
    if NYPLSecrets.cardCreatorPassword == nil {
      NYPLErrorLogger.logError(withCode: NYPLErrorCode.cardCreatorCredentialsDecodeFail,
                               summary:"CardCreator password decode error from NYPLSecrets")
    }

    return (username: NYPLSecrets.cardCreatorUsername ?? "",
            password: NYPLSecrets.cardCreatorPassword ?? "")
  }

  /// Factory method.
  /// - Returns: A configuration to be used in the regular card creation flow.
  @objc func makeRegularCardCreationConfiguration() -> CardCreatorConfiguration {
    let simplifiedBaseURL = libraryAccount?.details?.signUpUrl ?? APIKeys.cardCreatorEndpointURL

    let credentials = cardCreatorCredentials()
    let cardCreatorConfiguration = CardCreatorConfiguration(
      endpointURL: simplifiedBaseURL,
      endpointVersion: APIKeys.cardCreatorVersion,
      endpointUsername: credentials.username,
      endpointPassword: credentials.password,
      requestTimeoutInterval: requestTimeoutInterval)

    return cardCreatorConfiguration
  }

  /// Factory method.
  /// - Parameter parentBarcode: The barcode of the user creating the juvenile
  /// account. Differently from the sign-in process, this MUST be a barcode --
  /// the username will not work.
  /// - Returns: A coordinator instance to handle the juvenile card creator flow.
  private func makeJuvenileCardCreationCoordinator(using parentBarcode: String) -> JuvenileFlowCoordinator {

    let simplifiedBaseURL = libraryAccount?.details?.signUpUrl ?? APIKeys.cardCreatorEndpointURL
    let credentials = cardCreatorCredentials()
    let platformAPI = NYPLPlatformAPIInfo(
      oauthTokenURL: APIKeys.PlatformAPI.oauthTokenURL,
      clientID: NYPLSecrets.platformClientID,
      clientSecret: NYPLSecrets.platformClientSecret,
      baseURL: APIKeys.PlatformAPI.baseURL)

    let config = CardCreatorConfiguration(
      endpointURL: simplifiedBaseURL,
      endpointVersion: APIKeys.cardCreatorVersion,
      endpointUsername: credentials.username,
      endpointPassword: credentials.password,
      juvenileParentBarcode: parentBarcode,
      juvenilePlatformAPIInfo: platformAPI,
      requestTimeoutInterval: requestTimeoutInterval)

    return JuvenileFlowCoordinator(configuration: config)
  }

  /// Utility method to resolve the user barcode, accounting for NYPL-specific
  /// knowledge.
  private func userBarcode() -> String? {
    // For NYPL specifically, the authorizationIdentifier is always a valid
    // barcode.
    if libraryAccountID == libraryAccountsProvider.NYPLAccountUUID {
      return userAccount.authorizationIdentifier ?? userAccount.barcode
    }

    return userAccount.barcode
  }

  /// The entry point to the juvenile card creation flow.
  /// - Note: This is available only for NYPL accounts.
  /// - Parameters:
  ///   - eligibilityCompletion: Always called at the end of an initial
  ///   api call that determines whether the user is eligible or not to
  ///   create juvenile accounts. If that's possible, the handler returns
  ///   a navigation controller containing the VCs for the whole flow.
  ///   All the client has to do is to present this navigation controller
  ///   in whatever way it sees fit.
  ///   - flowCompletion: Called when/if the user completes the whole juvenile
  ///   card-creation flow.
  @objc
  func startJuvenileCardCreation(
    eligibilityCompletion: @escaping (UINavigationController?, Error?) -> Void,
    flowCompletion: @escaping () -> Void) {

    guard juvenileAuthLock.try() else {
      // not calling any completion because this means a flow is already going
      return
    }

    juvenileAuthIsOngoing = true

    guard let parentBarcode = userBarcode() else {
      let description = NSLocalizedString("Cannot confirm library card eligibility.", comment: "Message describing the fact that a patron's barcode is not readable and therefore we cannot establish eligibility to create dependent juvenile cards")
      let recoveryMsg = NSLocalizedString("Please log out and try your card information again.", comment: "A error recovery suggestion related to missing login info")

      let error = NSError(domain: NYPLSimplyEDomain,
                          code: NYPLErrorCode.missingParentBarcodeForJuvenile.rawValue,
                          userInfo: [
                            NSLocalizedDescriptionKey: description,
                            NSLocalizedRecoverySuggestionErrorKey: recoveryMsg])
      NYPLErrorLogger.logError(error,
                               summary: "Juvenile Card Creation: Parent barcode missing");
      eligibilityCompletion(nil, error)
      juvenileAuthIsOngoing = false
      juvenileAuthLock.unlock()
      return
    }

    let coordinator = makeJuvenileCardCreationCoordinator(using: parentBarcode)
    juvenileCardCreationCoordinator = coordinator

    coordinator.configuration.completionHandler = { [weak self] _, _, userInitiated in
      if userInitiated {
        self?.juvenileCardCreationCoordinator = nil
        flowCompletion()
      }
    }

    coordinator.startJuvenileFlow { [weak self] result in
      switch result {
      case .success(let navVC):
        eligibilityCompletion(navVC, nil)
      case .fail(let error):
        NYPLErrorLogger.logError(error,
                                 summary: "Juvenile Card Creation error")
        self?.juvenileCardCreationCoordinator = nil
        eligibilityCompletion(nil, error)
      }
      self?.juvenileAuthIsOngoing = false
      self?.juvenileAuthLock.unlock()
    }
  }

  /// Performs log out using the given executor verifying no book registry
  /// syncing or book downloads/returns authorizations are in progress.
  /// - Parameter logOutExecutor: The object actually performing the log out.
  /// - Returns: An alert the caller needs to present.
  @objc func logOutOrWarn(using logOutExecutor: NYPLLogOutExecutor) -> UIAlertController? {

    let title = NSLocalizedString("SignOut",
                                  comment: "Title for sign out action")
    let msg: String
    if bookRegistry.syncing {
      msg = NSLocalizedString("Your bookmarks and reading positions are in the process of being saved to the server. Would you like to stop that and continue logging out?",
                              comment: "Warning message offering the user the choice of interrupting book registry syncing to log out immediately, or waiting until that finishes.")
    } else if let drm = drmAuthorizer, drm.workflowsInProgress {
      msg = NSLocalizedString("It looks like you may have a book download or return in progress. Would you like to stop that and continue logging out?",
                              comment: "Warning message offering the user the choice of interrupting the download or return of a book to log out immediately, or waiting until that finishes.")
    } else {
      logOutExecutor.performLogOut()
      return nil
    }

    let alert = UIAlertController(title: title,
                                  message: msg,
                                  preferredStyle: .alert)
    alert.addAction(
      UIAlertAction(title: title,
                    style: .destructive,
                    handler: { _ in
                      logOutExecutor.performLogOut()
      }))
    alert.addAction(
      UIAlertAction(title: NSLocalizedString("Wait", comment: "button title"),
                    style: .cancel,
                    handler: nil))

    return alert
  }
}
