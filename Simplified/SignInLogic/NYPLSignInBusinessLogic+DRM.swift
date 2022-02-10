//
//  NYPLSignInBusinessLogic+DRM.swift
//  Simplified
//
//  Created by Ettore Pasquini on 10/28/20.
//  Copyright © 2020 NYPL. All rights reserved.
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
    
#if AXIS
    drmAuthorizeAxis(username: profileDoc.authorizationIdentifier ?? "",
                     password: profileDoc.authorizationIdentifier,
                     completion: axisAuthorizationCompletion(loggingContext))
#endif

#if FEATURE_DRM_CONNECTOR
    authorizeWithAdobe(userProfile: profileDoc,
                       loggingContext: loggingContext,
                       completion: adobeAuthorizationCompletion(loggingContext))
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
  
  // MARK: - Helper
    
#if FEATURE_DRM_CONNECTOR
  /// A completion block that logs error (if available), update user info
  /// and finalize sign in process after DRM authorization is completed,
  /// designated for Adobe DRM.
  private func adobeAuthorizationCompletion(_ loggingContext: [String: Any]) -> (
    (Bool, Error?, String?, String?) -> Void
  ) {
    return { [weak self] success, error, deviceID, userID in
      // make sure to cancel the previously scheduled selector
      // from the same thread it was scheduled on
      NYPLMainThreadRun.asyncIfNeeded {
        if let self = self {
          NSObject.cancelPreviousPerformRequests(withTarget: self)
        }
      }
      
      guard let self = self else {
        
        let error = NSError(
          domain: "NYPLSignInBusinessLogic deallocated prematurely",
          code: 418, userInfo: nil)
        
        NYPLErrorLogger.logLocalAuthFailed(error: error,
                                           library: nil,
                                           metadata: loggingContext)
      
        return
      }
      
      Log.info(#file, """
        Activation success: \(success)
        Error: \(error?.localizedDescription ?? "N/A")
        DeviceID: \(deviceID ?? "N/A")
        UserID: \(userID ?? "N/A")
        ***DRM Auth/Activation completion***
        """)

      var success = success

      if success, let userID = userID, let deviceID = deviceID {
        NYPLMainThreadRun.asyncIfNeeded {
          self.userAccount.setUserID(userID)
          self.userAccount.setDeviceID(deviceID)
        }
      } else {
        success = false
        NYPLErrorLogger.logLocalAuthFailed(error: error as NSError?,
                                           library: self.libraryAccount,
                                           metadata: loggingContext)
      }
      
      Log.info(#file, "Finalizing sign in for Adobe")
      self.finalizeSignIn(forDRMAuthorization: success,
                          error: error as NSError?)
    }
  }
#endif // FEATURE_DRM_CONNECTOR
  
#if AXIS
  /// A completion block that logs error (if available) and finalize sign in process
  /// after DRM authorization is completed, designated for AxisDRM.
  /// While it is very similar to the one for Adobe,
  /// it does not update the `userID` and `deviceID` because
  /// the AxisDRM does not return valid values of these parameters.
  /// It also avoid calling finalizeSignIn twice when both Adobe and Axis exist.
  private func axisAuthorizationCompletion(_ loggingContext: [String: Any]) -> (
    (Bool, Error?, String?, String?) -> Void
  ) {
    return { [weak self] success, error, deviceID, userID in
      guard let self = self else {
        
        let error = NSError(
          domain: "NYPLSignInBusinessLogic deallocated prematurely",
          code: 418, userInfo: nil)
        
        NYPLErrorLogger.logLocalAuthFailed(error: error,
                                           library: nil,
                                           metadata: loggingContext)
      
        return
      }
      
      Log.info(#file, """
        Activation success: \(success)
        Error: \(error?.localizedDescription ?? "N/A")
        DeviceID: \(deviceID ?? "N/A")
        UserID: \(userID ?? "N/A")
        ***DRM Auth/Activation completion***
        """)

      let success = success && userID != nil && deviceID != nil

      if !success {
        NYPLErrorLogger.logLocalAuthFailed(error: error as NSError?,
                                           library: self.libraryAccount,
                                           metadata: loggingContext)
      }

#if !FEATURE_DRM_CONNECTOR
      // finalizeSignIn should only be called once,
      // so here we are calling it if only AXIS is the available DRM
      self.finalizeSignIn(forDRMAuthorization: success,
                          error: error as NSError?)
#endif
    }
  }
#endif // AXIS
}
#endif // FEATURE_DRM_CONNECTOR || AXIS
