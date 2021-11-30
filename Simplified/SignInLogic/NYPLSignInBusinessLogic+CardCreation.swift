//
//  NYPLSignInBusinessLogic+CardCreation.swift
//  Simplified
//
//  Created by Ettore Pasquini on 11/2/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation
import NYPLCardCreator

extension FlowCoordinator: FlowCoordinating {}

extension NYPLSignInBusinessLogic {
  /// The entry point to the regular card creation flow.
  /// - Note: This is available only for NYPL accounts.
  /// - Parameters:
  ///   - completion: Always called whether the library supports
  ///   card creation or not. If it's possible, the handler returns
  ///   a navigation controller containing the VCs for the whole flow.
  ///   All the client has to do is to present this navigation controller
  ///   in whatever way it sees fit.
  @objc
  func startRegularCardCreation(completion: @escaping (UINavigationController?, Error?) -> Void) {
    // We don't necessary need the lock for regular card creation flow
    // since there is no API call on eligibility check. Since the mechanism is already
    // implemented, there is no harm to future proof this part of code.
    guard cardCreationLock.try() else {
      // not calling any completion because this means a flow is already going
      return
    }

    cardCreationIsOngoing = true

    // If the library does not have a sign-up url, there's nothing we can do
    guard let signUpURL = libraryAccount?.details?.signUpUrl else {
      let description = NSLocalizedString("We're sorry. Currently we do not support signups for new patrons via the app.", comment: "Message describing the fact that new patron sign up is not supported by the current selected library")
      let error = NSError(domain: NYPLErrorLogger.clientDomain,
                          code: NYPLErrorCode.nilSignUpURL.rawValue,
                          userInfo: [
                            NSLocalizedDescriptionKey: description])
      NYPLErrorLogger.logError(withCode: .nilSignUpURL,
                               summary: "SignUp Error in Settings: nil signUp URL",
                               metadata: [
                                "libraryAccountUUID": libraryAccountID,
                                "libraryAccountName": libraryAccount?.name ?? "N/A",
      ])
      completion(nil, error)
      cardCreationIsOngoing = false
      cardCreationLock.unlock()
      return
    }

    // Verify if the native card creator is supported for this library,
    // otherwise default to web
    guard libraryAccount?.details?.supportsCardCreator ?? false else {
      let title = NSLocalizedString("eCard",
                                    comment: "Title for web-based card creator page")
      let msg = NSLocalizedString("We're sorry. Our sign up system is currently down. Please try again later.",
                                  comment: "Message for error loading the web-based card creator")
      let webVC = RemoteHTMLViewController(URL: signUpURL,
                                           title: title,
                                           failureMessage: msg)
      completion(UINavigationController(rootViewController: webVC), nil)
      cardCreationIsOngoing = false
      cardCreationLock.unlock()
      return
    }

    startRegularFlow(completion: completion)
  }

  private func startRegularFlow(completion: @escaping (UINavigationController?, Error?) -> Void) {

    guard let coordinator = makeCardCreationCoordinator() else {
      // This should only happen when CardCreator credentials decode failed (which is very unlikely to happen)
      // and the errors are already logged when we retrieve the credentials
      let description = NSLocalizedString("We're sorry. Our sign up system is currently down. Please try again later.", comment: "Message describing the CardCreator flow failed to be initiated")
      let error = NSError(domain: NYPLErrorLogger.clientDomain,
                          code: NYPLErrorCode.cardCreatorCredentialsDecodeFail.rawValue,
                          userInfo: [
                            NSLocalizedDescriptionKey: description
                          ])
      completion(nil, error)
      cardCreationIsOngoing = false
      cardCreationLock.unlock()
      return
    }

    cardCreationCoordinator = coordinator

    coordinator.configuration.completionHandler = { [weak self] username, pin, isUserInitiated in
      if isUserInitiated {
        // Dismiss CardCreator when user finishes Credential Review
        self?.uiDelegate?.dismiss(animated: true, completion: nil)
      } else {
        if let usernameTextField = self?.uiDelegate?.usernameTextField, let PINTextField = self?.uiDelegate?.PINTextField {
          usernameTextField.text = username
          PINTextField.text = pin
        }
        self?.isLoggingInAfterSignUp = true
        self?.logIn()
      }
      self?.cardCreationCoordinator = nil
    }
    
    coordinator.startRegularFlow { [weak self] result in
      switch result {
      case .success(let navVC):
        completion(navVC, nil)
      case .fail(let error):
        NYPLErrorLogger.logError(error, summary: "Regular Card Creation error")
        completion(nil, error)
        self?.cardCreationIsOngoing = false
        self?.cardCreationCoordinator = nil
      }
      self?.cardCreationLock.unlock()
    }
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

    guard cardCreationLock.try() else {
      // not calling any completion because this means a flow is already going
      return
    }

    cardCreationIsOngoing = true

    guard let parentBarcode = resolveUserBarcode() else {
      let description = NSLocalizedString("Your eligibility for this card can't be confirmed. Please contact your library if this is in error.", comment: "Message describing the fact that a patron's barcode is not readable and therefore we cannot establish eligibility to create dependent juvenile cards")
      let recoveryMsg = NSLocalizedString("Please log out and try your card information again.", comment: "A error recovery suggestion related to missing login info")

      let error = NSError(domain: NYPLErrorLogger.clientDomain,
                          code: NYPLErrorCode.missingParentBarcodeForJuvenile.rawValue,
                          userInfo: [
                            NSLocalizedDescriptionKey: description,
                            NSLocalizedRecoverySuggestionErrorKey: recoveryMsg])
      NYPLErrorLogger.logError(error,
                               summary: "Juvenile Card Creation: Parent barcode missing");
      eligibilityCompletion(nil, error)
      cardCreationIsOngoing = false
      cardCreationLock.unlock()
      return
    }

    guard let coordinator = makeCardCreationCoordinator(using:parentBarcode) else {
      self.cardCreationIsOngoing = false
      self.cardCreationLock.unlock()
      return
    }
    cardCreationCoordinator = coordinator

    coordinator.configuration.completionHandler = { [weak self] _, _, userInitiated in
      if userInitiated {
        self?.cardCreationCoordinator = nil
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
        self?.cardCreationCoordinator = nil
        eligibilityCompletion(nil, error)
      }
      self?.cardCreationIsOngoing = false
      self?.cardCreationLock.unlock()
    }
  }

  @objc func checkCardCreationEligibility(completion: @escaping () -> Void) {
    guard let parentBarcode = self.resolveUserBarcode() else {
      Log.info(#function, "Ineligible for card creation: no barcode.")
      allowJuvenileCardCreation = false
      completion()
      return
    }
    
    guard let coordinator = cardCreationCoordinator ?? makeCardCreationCoordinator(using: parentBarcode) else {
      Log.error(#function, "Ineligible for card creation: Card Creator credentials invalid.")
      allowJuvenileCardCreation = false
      completion()
      return
    }
    cardCreationCoordinator = coordinator

    coordinator.checkJuvenileCreationEligibility(parentBarcode: parentBarcode) { [weak self] error in
      Log.info(#function, "Juvenile eligibility: \(error == nil). Error: \(String(describing: error))")
      self?.allowJuvenileCardCreation = (error == nil)
      completion()
    }
  }

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
  /// - Parameter parentBarcode: Optional. Only pass in barcode for creating juvenile
  /// account. Differently from the sign-in process, this MUST be a barcode --
  /// the username will not work.
  /// - Returns: A configuration to be used in the regular or juvenile card
  /// creation flow, unless the API client ID and secret are missing.
  @objc func makeCardCreationConfiguration(using parentBarcode: String = "") -> CardCreatorConfiguration? {
    let credentials = cardCreatorCredentials()
    guard let platformAPI = NYPLPlatformAPIInfo(
      oauthTokenURL: NYPLPlatformAPI.oauthTokenURL,
      clientID: NYPLSecrets.platformClientID,
      clientSecret: NYPLSecrets.platformClientSecret,
      baseURL: NYPLPlatformAPI.baseURL
    ) else {
      return nil
    }
    
    let cardCreatorConfiguration = CardCreatorConfiguration(
      endpointUsername: credentials.username,
      endpointPassword: credentials.password,
      platformAPIInfo: platformAPI,
      juvenileParentBarcode: parentBarcode,
      requestTimeoutInterval: networker.requestTimeout)

    return cardCreatorConfiguration
  }

  /// Factory method.
  /// - Parameter parentBarcode: Optional. Only pass in barcode for creating juvenile
  /// account. Differently from the sign-in process, this MUST be a barcode --
  /// the username will not work.
  /// - Returns: A coordinator instance to handle the juvenile card creator flow.
  func makeCardCreationCoordinator(using parentBarcode: String = "") -> FlowCoordinator? {
    guard let config = makeCardCreationConfiguration(using: parentBarcode) else {
      return nil
    }

    return FlowCoordinator(configuration: config)
  }

  /// Utility method to resolve the user barcode, accounting for NYPL-specific
  /// knowledge.
  func resolveUserBarcode() -> String? {
    // For NYPL specifically, the authorizationIdentifier is always a valid
    // barcode.
    if libraryAccountID == libraryAccountsProvider.NYPLAccountUUID {
      return userAccount.authorizationIdentifier ?? userAccount.barcode
    }

    return userAccount.barcode
  }
}
