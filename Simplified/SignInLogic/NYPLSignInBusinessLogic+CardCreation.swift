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
                               message: nil,
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
      let msg = NSLocalizedString("SettingsConnectionFailureMessage",
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
}
