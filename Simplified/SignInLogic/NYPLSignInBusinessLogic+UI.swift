//
//  NYPLSignInBusinessLogic+UI.swift
//  Simplified
//
//  Created by Ettore Pasquini on 10/26/20.
//  Copyright © 2020 NYPL. All rights reserved.
//

import UIKit

extension NYPLSignInBusinessLogic {

  /// Finalizes the sign in process.
  ///
  /// In order, the following tasks are performed:
  /// 1. update the user account for the library we are signing in to,
  /// 2. if there was a DRM error, notify the user (via uiDelegate) and exit,
  /// 3. call the `refreshAuthCompletion` in case that was set,
  /// 4. dismiss the presented view controller in case the `uiDelegate` was a modal,
  /// 5. call the `uiDelegate` `businessLogicDidSignIn(_:)` callback,
  /// 6. refresh / sync the BookRegistry.
  ///
  /// - Note: This does not log the error/message to Crashlytics.
  /// - Parameters:
  ///   - drmSuccess: whether the DRM authorization was successful or not.
  ///   Pass `true` if the library where the sign-in happened does not support
  ///   any DRM or if app is built without DRM support.
  ///   - error: The error encountered during sign-in, if any.
  ///   - errorMessage: Error message to display, taking priority over `error`.
  ///   This can be a localization key.
  func finalizeSignIn(forDRMAuthorization drmSuccess: Bool,
                      error: Error? = nil,
                      errorMessage: String? = nil) {

    self.updateUserAccount(forDRMAuthorization: drmSuccess,
                           withBarcode: self.uiDelegate?.username,
                           pin: self.uiDelegate?.pin,
                           authToken: self.authToken,
                           patron: self.patron,
                           cookies: self.cookies)

    guard drmSuccess else {
      NotificationCenter.default.post(name: .NYPLSyncEnded, object: nil)

      NYPLMainThreadRun.asyncIfNeeded { [self] in
        self.uiDelegate?.businessLogic(self,
                                       didEncounterValidationError: error,
                                       userFriendlyErrorTitle: "SettingsAccountViewControllerLoginFailed",
                                       andMessage: errorMessage)
      }
      return
    }

    // no need to force a login, as we just logged in successfully
    self.ignoreSignedInState = false

    let refreshCompletion = self.refreshAuthCompletion
    self.refreshAuthCompletion = nil

    NYPLMainThreadRun.asyncIfNeeded { [self] in
      if !self.isLoggingInAfterSignUp, let vc = self.uiDelegate as? UIViewController {
        // don't dismiss anything if the vc is not even on the view stack
        if vc.view.superview != nil || vc.presentingViewController != nil {
          self.uiDelegate?.dismiss(animated: true, completion: refreshCompletion)
          self.notifyUIDelegateAndSync()
          return
        }
      }

      refreshCompletion?()
      self.notifyUIDelegateAndSync()
    }
  }

  private func notifyUIDelegateAndSync() {
    Log.debug(#function, "will call didCompleteSignIn async on credentialsUpdateQueue...")
    self.userAccount.credentialsUpdateQueue.async { [weak self] in
      guard let self = self else { return }
      NotificationCenter.default.post(name: .NYPLIsSigningIn, object: false)
      self.uiDelegate?.businessLogicDidSignIn(self)
      self.refreshBookRegistryIfNeeded()
    }
  }

  private func refreshBookRegistryIfNeeded() {
    if libraryAccountID == libraryAccountsProvider.currentAccountId {
      bookRegistry.syncResettingCache(false) { [weak bookRegistry] errorDict in
        if errorDict == nil {
          bookRegistry?.save()
        }
      }
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
    } else if (drmAuthorizerAdobe?.workflowsInProgress ?? false) ||
                (drmAuthorizerAxis?.workflowsInProgress ?? false) {
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
