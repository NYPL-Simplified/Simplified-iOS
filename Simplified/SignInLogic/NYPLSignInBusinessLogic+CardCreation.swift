//
//  NYPLSignInBusinessLogic+CardCreation.swift
//  Simplified
//
//  Created by Ettore Pasquini on 11/2/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation
import NYPLCardCreator

extension NYPLSignInBusinessLogic {
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

    return CardCreator.initialNavigationControllerWithConfiguration(config)
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
      requestTimeoutInterval: requestTimeoutInterval)

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
      requestTimeoutInterval: requestTimeoutInterval)

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
