//
//  NYPLSignInBusinessLogic+CardCreation.swift
//  Simplified
//
//  Created by Ettore Pasquini on 11/2/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation
import NYPLCardCreator

extension JuvenileFlowCoordinator: JuvenileFlowCoordinating {}

extension NYPLSignInBusinessLogic {

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

    guard let parentBarcode = resolveUserBarcode() else {
      let description = NSLocalizedString("Cannot confirm library card eligibility.", comment: "Message describing the fact that a patron's barcode is not readable and therefore we cannot establish eligibility to create dependent juvenile cards")
      let recoveryMsg = NSLocalizedString("Please log out and try your card information again.", comment: "A error recovery suggestion related to missing login info")

      let error = NSError(domain: NYPLErrorLogger.clientDomain,
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

  @objc func checkCardCreationEligibility(completion: @escaping () -> Void) {
    guard let parentBarcode = self.resolveUserBarcode() else {
      Log.info(#function, "Ineligible for card creation: no barcode.")
      allowJuvenileCardCreation = false
      completion()
      return
    }

    let coordinator = juvenileCardCreationCoordinator ?? makeJuvenileCardCreationCoordinator(using: parentBarcode)
    juvenileCardCreationCoordinator = coordinator

    coordinator.checkJuvenileCreationEligibility(parentBarcode: parentBarcode) { [weak self] error in
      Log.info(#function, "Juvenile eligibility: \(error == nil). Error: \(String(describing: error))")
      self?.allowJuvenileCardCreation = (error == nil)
      completion()
    }
  }

  @objc func makeCardCreatorIfPossible() -> UINavigationController? {

    // if the library does not have a sign-up url, there's nothing we can do
    guard let signUpURL = libraryAccount?.details?.signUpUrl else {
      NYPLErrorLogger.logError(withCode: .nilSignUpURL,
                               summary: "SignUp Error in Settings: nil signUp URL",
                               metadata: [
                                "libraryAccountUUID": libraryAccountID,
                                "libraryAccountName": libraryAccount?.name ?? "N/A",
      ])
      return nil
    }

    // verify if the native card creator is supported for this library,
    // otherwise default to web
    guard libraryAccount?.details?.supportsCardCreator ?? false else {
      let title = NSLocalizedString("eCard",
                                    comment: "Title for web-based card creator page")
      let msg = NSLocalizedString("The page could not load due to a connection error.",
                                  comment: "Message for errors loading a HTML page")
      let webVC = RemoteHTMLViewController(URL: signUpURL,
                                           title: title,
                                           failureMessage: msg)
      return UINavigationController(rootViewController: webVC)
    }

    let config = makeRegularCardCreationConfiguration()
    config.completionHandler = { [weak self] username, pin, isUserInitiated in
      guard let self = self else {
        return
      }

      if isUserInitiated {
        // Dismiss CardCreator when user finishes Credential Review
        self.uiDelegate?.dismiss(animated: true, completion: nil)
      } else {
        if let usernameTextField = self.uiDelegate?.usernameTextField, let PINTextField = self.uiDelegate?.PINTextField {
          usernameTextField.text = username
          PINTextField.text = pin
        }
        self.isLoggingInAfterSignUp = true
        self.logIn()
      }
    }

    return CardCreator.initialNavigationController(configuration: config)
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
  /// - Returns: A configuration to be used in the regular card creation flow.
  @objc func makeRegularCardCreationConfiguration() -> CardCreatorConfiguration {
    let simplifiedBaseURL = libraryAccount?.details?.signUpUrl ?? APIKeys.cardCreatorEndpointURL

    let credentials = cardCreatorCredentials()
    let cardCreatorConfiguration = CardCreatorConfiguration(
      endpointURL: simplifiedBaseURL,
      endpointVersion: APIKeys.cardCreatorVersion,
      endpointUsername: credentials.username,
      endpointPassword: credentials.password,
      requestTimeoutInterval: networker.requestTimeout)

    return cardCreatorConfiguration
  }

  /// Factory method.
  /// - Parameter parentBarcode: The barcode of the user creating the juvenile
  /// account. Differently from the sign-in process, this MUST be a barcode --
  /// the username will not work.
  /// - Returns: A coordinator instance to handle the juvenile card creator flow.
  func makeJuvenileCardCreationCoordinator(using parentBarcode: String) -> JuvenileFlowCoordinator {

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
      requestTimeoutInterval: networker.requestTimeout)

    return JuvenileFlowCoordinator(configuration: config)
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
