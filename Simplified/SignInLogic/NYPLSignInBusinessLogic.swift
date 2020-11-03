//
//  NYPLSignInBusinessLogic.swift
//  Simplified
//
//  Created by Ettore Pasquini on 5/5/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

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
  func isUserAuthorized(_ userID: String!, withDevice device: String!) -> Bool
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
    self.samlHelper = NYPLSAMLHelper()
    self.urlSessionDelegate = NYPLSignInURLSessionChallengeHandler(uiDelegate: uiDelegate)
    self.urlSession = URLSession(configuration: .ephemeral,
                                 delegate: urlSessionDelegate,
                                 delegateQueue: OperationQueue.main)
    super.init()
    self.samlHelper.businessLogic = self
  }

  deinit {
    self.urlSession.finishTasksAndInvalidate()
  }

  // Lock for ensure internal state consistency.
  private let permissionsCheckLock = NSLock()

  /// Signing in and out may imply syncing the book registry.
  let bookRegistry: NYPLBookRegistrySyncing

  /// Provides the user account for a given library.
  private let userAccountProvider: NYPLUserAccountProvider.Type

  /// THe object determining whether there's an ongoing DRM authorization.
  weak private(set) var drmAuthorizer: NYPLDRMAuthorizing?

  /// The primary way for the business logic to communicate with the UI.
  @objc weak var uiDelegate: NYPLSignInBusinessLogicUIDelegate?

  private var uiContext: String {
    return uiDelegate?.context ?? "Unknown"
  }

  /// This flag should be set if the instance is used to register new users.
  @objc var isLoggingInAfterSignUp: Bool = false

  /// A closure to be invoked at the end of the sign-in process.
  @objc var completionHandler: (() -> Void)? = nil

  // MARK:- OAuth / SAML / Clever Info

  /// The current OAuth token if available.
  var authToken: String? = nil

  /// The current patron info if available.
  var patron: [String: Any]? = nil

  /// Settings used by OAuth sign-in flows.
  let universalLinksSettings: NYPLUniversalLinksSettings

  /// Cookies used to authenticate. Only required for the SAML flow.
  @objc var cookies: [HTTPCookie]?

  /// Performs initiation rites for SAML sign-in.
  let samlHelper: NYPLSAMLHelper

  /// This overrides the sign-in state logic to behave as if the user isn't
  /// authenticated. This is useful if we already have credentials, but
  /// the session expired (e.g. SAML flow).
  var ignoreSignedInState: Bool = false

  /// This is `true` during the process of signing in / validating credentials.
  var isCurrentlySigningIn = false

  // MARK:- Juvenile Card Creation Info

  private let juvenileAuthLock = NSLock()
  @objc private(set) var juvenileAuthIsOngoing = false
  private var juvenileCardCreationCoordinator: JuvenileFlowCoordinator?

  // MARK:- Library Accounts Info

  /// The ID of the library this object is signing in to.
  /// - Note: This is also provided by `libraryAccountsProvider::currentAccount`
  /// but that could be returning nil if called too early on.
  let libraryAccountID: String

  /// The object providing library account information.
  private let libraryAccountsProvider: NYPLLibraryAccountsProvider

  @objc var libraryAccount: Account? {
    return libraryAccountsProvider.account(libraryAccountID)
  }

  var selectedIDP: OPDS2SamlIDP?

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

  // MARK:- Network Requests Logic

  // Time-out to use for sign-in/out network requests.
  private let requestTimeoutInterval: TimeInterval = 25.0

  private let urlSession: URLSession

  private let urlSessionDelegate: NYPLSignInURLSessionChallengeHandler

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
                                 message: "Unable to create URL for \(authTypeStr)")
        return nil
    }

    var req = URLRequest(url: url)
    req.timeoutInterval = requestTimeoutInterval

    if let selectedAuth = selectedAuthentication,
      (selectedAuth.isOauth || selectedAuth.isSaml) {

      // The nil-coalescing on the authToken covers 2 cases:
      // - sign in, where uiDelegate has the token because we just obtained it
      // externally (via OAuth) but user account may not have been updated yet;
      // - sign out, where the uiDelegate may not have the token unless the user
      // just signed in, but the user account will definitely have it.
      if let authToken = (authToken ?? userAccount.authToken) {
        // Note: this is officially unsupported by the URL loading system
        // in iOS but it does work. It is necessary because the officially
        // supported method of providing authorization info to a request is via
        // `URLAuthenticationChallenge`, which has no api for Bearer token
        // authentication. Basic auth via username + password works fine with
        // challenges (see `NYPLSignInURLSessionChallengeHandler`).
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

  /// After having obtained the credentials for all authentication methods,
  /// including those that require negotiation with 3rd parties (such as
  /// Clever and SAML), validate said credentials against the Circulation
  /// Manager servers and call back to the UI once that's concluded.
  func validateCredentials() {
    isCurrentlySigningIn = true

    guard let req = makeRequest(for: .signIn, context: uiContext) else {
      NYPLMainThreadRun.asyncIfNeeded {
        let error = NSError(domain: NYPLSimplyEDomain,
                            code: NYPLErrorCode.noURL.rawValue,
                            userInfo: [
                              NSLocalizedDescriptionKey:
                                NSLocalizedString("Unable to contact server because the server didn't provide a URL for signing in.",
                                                  comment: "Error message for when the library profile url is missing from the authentication document the server provided."),
                              NSLocalizedRecoverySuggestionErrorKey:
                                NSLocalizedString("Try force-quitting the app and repeat the sign-in process.",
                                                  comment: "Recovery instructions for when the URL to sign in is missing")])
        self.handleNetworkError(error,
                                problemDocData: nil,
                                response: nil,
                                loggingContext: ["Context": self.uiContext])
      }
      return
    }

    let task = urlSession.dataTask(with: req) { [weak self] data, response, error in
      guard let self = self else {
        return
      }

      let loggingContext: [String: Any] = [
        "Request": req.loggableString,
        "Response": response ?? "N/A",
        "Attempted Barcode": self.uiDelegate?.username?.md5hex() ?? "N/A",
        "Data is nil?": "\(data == nil)",
        "Context": self.uiContext]

      guard
        let httpResponse = response as? HTTPURLResponse,
        httpResponse.statusCode == 200,
        let responseData = data else {
          self.handleNetworkError(error as NSError?,
                                  problemDocData: data,
                                  response: response,
                                  loggingContext: loggingContext)
          return
      }

      self.isCurrentlySigningIn = false

      #if FEATURE_DRM_CONNECTOR
      self.drmAuthorizeUserData(responseData,
                                loggingContext: loggingContext)
      #else
      self.uiDelegate?.finalizeSignIn(forDRMAuthorization: true,
                                      error: nil,
                                      errorMessage: nil)
      #endif
    }

    task.resume()
  }

  private func handleNetworkError(_ error: Error?,
                                  problemDocData: Data?,
                                  response: URLResponse?,
                                  loggingContext: [String: Any]?) {
    let problemDoc: NYPLProblemDocument?
    if let problemDocData = problemDocData, response?.isProblemDocument() ?? false {
      do {
        problemDoc = try NYPLProblemDocument.fromData(problemDocData)
      } catch(let parseError) {
        problemDoc = nil
        NYPLErrorLogger.logProblemDocumentParseError(parseError as NSError,
                                                     problemDocumentData: problemDocData,
                                                     url: nil,
                                                     summary: "Sign-in validation: Problem Doc parse error",
                                                     metadata: loggingContext)
      }
    } else {
      problemDoc = nil
    }

    // if there's no response it's a client-side error that we already logged
    if response != nil {
      NYPLErrorLogger.logLoginError(error as NSError?,
                                    library: libraryAccount,
                                    response: response,
                                    problemDocument: problemDoc,
                                    metadata: loggingContext)
    }

    let title, message: String?
    if let problemDoc = problemDoc {
      title = problemDoc.title
      message = problemDoc.detail
    } else {
      title = "SettingsAccountViewControllerLoginFailed"
      message = nil
    }

    uiDelegate?.businessLogic(self,
                              didEncounterValidationError: error,
                              userFriendlyErrorTitle: title,
                              andMessage: message)
  }

  /// Initiates process of signing in with the server.
  @objc func logIn() {
    NotificationCenter.default.post(name: .NYPLIsSigningIn, object: true)

    NYPLMainThreadRun.asyncIfNeeded {
      self.uiDelegate?.businessLogicWillSignIn(self)
    }

    if selectedAuthentication?.isOauth ?? false {
      oauthLogIn()
    } else if selectedAuthentication?.isSaml ?? false {
      samlHelper.logIn()
    } else {
      validateCredentials()
    }
  }

  @objc var isAuthenticationDocumentLoading: Bool = false

  /// Makes sure we have the `libraryAccount` `details` loading the
  /// authentication document if needed.
  /// - Note: if an error occurs while loading the authentication document,
  /// an error is reported via `NYPLErrorLogger`.
  /// - Parameter completion: Always called once we have the library details.
  @objc func ensureAuthenticationDocumentIsLoaded(_ completion: @escaping (Bool) -> Void) {
    if libraryAccount?.details != nil {
      completion(true)
      return
    }

    isAuthenticationDocumentLoading = true
    libraryAccount?.loadAuthenticationDocument(using: self) { success in
      self.isAuthenticationDocumentLoading = false
      completion(success)
    }
  }

  // MARK:- User Account Management

  /// The user account for the library we are signing in to.
  var userAccount: NYPLUserAccount {
    return userAccountProvider.sharedAccount(libraryUUID: libraryAccountID)
  }

  /// Updates the user account for the library we are signing in to.
  /// - Parameters:
  ///   - drmSuccess: whether the DRM authorization was successful or not.
  ///   Ignored if the app is built without DRM support.
  ///   - barcode: The new barcode, if available.
  ///   - pin: The new PIN, if barcode is provided.
  ///   - authToken: the token if `selectedAuthentication` is OAuth or SAML. 
  ///   - patron: The patron info for OAuth / SAML authentication.
  ///   - cookies: Cookies for SAML authentication.
  func updateUserAccount(forDRMAuthorization drmSuccess: Bool,
                         withBarcode barcode: String?,
                         pin: String?,
                         authToken: String?,
                         patron: [String:Any]?,
                         cookies: [HTTPCookie]?) {
    #if FEATURE_DRM_CONNECTOR
    guard drmSuccess else {
      userAccount.removeAll()
      return
    }
    #endif

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

  private func setBarcode(_ barcode: String?, pin: String?) {
    if let barcode = barcode, let pin = pin {
      userAccount.setBarcode(barcode, PIN:pin)
    }
  }

  // MARK: - Available Features Checks

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

  /// - Returns: Whether it is possible to sign up for a new account or not.
  func registrationIsPossible() -> Bool {
    return !isSignedIn() && NYPLConfiguration.cardCreationEnabled() && libraryAccount?.details?.signUpUrl != nil
  }

  /// - Returns: Whether it is possible to sign up using the native card
  /// creator.
  func registrationViaCardCreatorIsPossible() -> Bool {
    return registrationIsPossible() &&
      (libraryAccount?.details?.supportsCardCreator ?? false)
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

  // MARK: - Bookmark Syncing

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
}
