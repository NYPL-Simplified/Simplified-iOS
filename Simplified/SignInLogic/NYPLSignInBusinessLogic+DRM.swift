//
//  NYPLSignInBusinessLogic+DRM.swift
//  Simplified
//
//  Created by Ettore Pasquini on 10/28/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

#if FEATURE_DRM_CONNECTOR || AXIS

extension NYPLSignInBusinessLogic {

  /// Extract authorization credentials from binary data and perform DRM
  /// authorization request.
  ///
  /// - Parameters:
  ///   - data: The binary data containing the DRM authorization info.
  ///   - loggingContext: Information to report when logging errors.
  func drmAuthorizeUserData(_ data: Data, loggingContext: [String: Any]) {
    let profileDoc: UserProfileDocument
    do {
      profileDoc = try UserProfileDocument.fromData(data)
    } catch {
      NYPLErrorLogger.logUserProfileDocumentAuthError(error as NSError,
                                                      summary:"SignIn: unable to parse user profile doc",
                                                      barcode: nil,
                                                      metadata:loggingContext)
      finalizeSignIn(forDRMAuthorization: false,
                     errorMessage: "Error parsing user profile document")
      return
    }

    if let authID = profileDoc.authorizationIdentifier {
      userAccount.setAuthorizationIdentifier(authID)
    } else {
      NYPLErrorLogger.logError(withCode: .noAuthorizationIdentifier,
                               summary: "SignIn: no authorization ID in user profile doc",
                               metadata: loggingContext)
    }
    
    #if FEATURE_DRM_CONNECTOR
    authorizeWithAdobe(userProfile: profileDoc, loggingContext: loggingContext)
    #elseif AXIS
    drmAuthorize(username: profileDoc.authorizationIdentifier ?? "",
                 password: profileDoc.authorizationIdentifier,
                 loggingContext: loggingContext)
    #endif
  }

  @objc func dismissAfterUnexpectedDRMDelay(_ arg: Any) {
    NYPLMainThreadRun.asyncIfNeeded {
      let title = NSLocalizedString("Sign In Error",
                                    comment: "Title for sign in error alert")
      let message = NSLocalizedString("The DRM Library is taking longer than expected. Please wait and try again later.\n\nIf the problem persists, try to sign out and back in again from the Library Settings menu.",
                                      comment: "Message for sign-in error alert caused by failed DRM authorization")

      let alert = UIAlertController(title: title, message: message,
                                    preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"),
                                    style: .default) { [weak self] action in
                                      self?.uiDelegate?.dismiss(animated: true,
                                                                completion: nil)
      })

      NYPLAlertUtils.presentFromViewControllerOrNil(alertController: alert,
                                                    viewController: nil,
                                                    animated: true,
                                                    completion: nil)
    }
  }

  @objc func logInIfUserAuthorized() {
    if let drmAuthorizer = drmAuthorizer,
      !drmAuthorizer.isUserAuthorized(userAccount.userID,
                                      withDevice: userAccount.deviceID) {

      if userAccount.hasBarcodeAndPIN() && !isValidatingCredentials {
        if let usernameTextField = uiDelegate?.usernameTextField,
          let PINTextField = uiDelegate?.PINTextField
        {
          usernameTextField.text = userAccount.barcode
          PINTextField.text = userAccount.PIN
        }

        logIn()
      }
    }
  }
}

#endif
