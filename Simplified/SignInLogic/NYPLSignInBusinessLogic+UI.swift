//
//  NYPLSignInBusinessLogic+UI.swift
//  Simplified
//
//  Created by Ettore Pasquini on 10/26/20.
//  Copyright © 2020 NYPL. All rights reserved.
//

import UIKit

extension NYPLSignInBusinessLogic {

  /// Finalizes the sign in process by updating the user account for the
  /// library we are signing in to and calling the completion handler in
  /// case that was set, as well as dismissing the presented view controller
  /// in case the `uiDelegate` was a modal.
  /// - Note: This does not log the error/message to Crashlytics.
  /// - Parameters:
  ///   - drmSuccess: whether the DRM authorization was successful or not.
  ///   Ignored if the app is built without DRM support.
  ///   - error: The error encountered during sign-in, if any.
  ///   - errorMessage: Error message to display, taking priority over `error`.
  ///   This can be a localization key.
  func finalizeSignIn(forDRMAuthorization drmSuccess: Bool,
                      error: Error? = nil,
                      errorMessage: String? = nil) {
    NYPLMainThreadRun.asyncIfNeeded {
      defer {
        self.uiDelegate?.businessLogicDidCompleteSignIn(self)
      }

      self.updateUserAccount(forDRMAuthorization: drmSuccess,
                             withBarcode: self.uiDelegate?.username,
                             pin: self.uiDelegate?.pin,
                             authToken: self.authToken,
                             patron: self.patron,
                             cookies: self.cookies)

      #if FEATURE_DRM_CONNECTOR
      guard drmSuccess else {
        NotificationCenter.default.post(name: .NYPLSyncEnded, object: nil)

        let alert = NYPLAlertUtils.alert(title: "SettingsAccountViewControllerLoginFailed",
                                         message: errorMessage,
                                         error: error as NSError?)
        NYPLPresentationUtils.safelyPresent(alert, animated: true)
        return
      }
      #endif

      // no need to force a login, as we just logged in successfully
      self.ignoreSignedInState = false

      let completionHandler = self.refreshAuthCompletion
      self.refreshAuthCompletion = nil

      if !self.isLoggingInAfterSignUp, let vc = self.uiDelegate as? UIViewController {
        // don't dismiss anything if the vc is not even on the view stack
        if vc.view.superview != nil || vc.presentingViewController != nil {
          self.uiDelegate?.dismiss(animated: true, completion: completionHandler)
          return
        }
      }

      completionHandler?()
    }
  }

  /// Performs log out verifying that no book registry syncing
  /// or book download/return authorizations are in progress.
  /// - Returns: An alert the caller needs to present in case there's syncing
  /// or book downloading/returning currently happening.
  @objc func logOutOrWarn() -> UIAlertController? {

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
      performLogOut()
      return nil
    }

    let alert = UIAlertController(title: title,
                                  message: msg,
                                  preferredStyle: .alert)
    alert.addAction(
      UIAlertAction(title: title,
                    style: .destructive,
                    handler: { _ in
                      self.performLogOut()
      }))
    alert.addAction(
      UIAlertAction(title: NSLocalizedString("Wait", comment: "button title"),
                    style: .cancel,
                    handler: nil))

    return alert
  }
}
