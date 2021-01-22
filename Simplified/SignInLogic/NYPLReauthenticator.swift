//
//  NYPLReauthenticator.swift
//  Simplified
//
//  Created by Ettore Pasquini on 11/18/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

/// This class is a front-end for taking care of situations where an
/// already authenticated user somehow sees its requests fail with a 401
/// HTTP status as it the request lacked proper authentication.
///
/// This typically involves refreshing the authentication token and, depending
/// on the chosen authentication method, opening up a sign-in VC to interact
/// with the user.
///
/// This class takes care of initializing the VC's UI, its business logic,
/// opening up the VC when needed, and performing the log-in request under
/// the hood when no user input is needed.
@objc class NYPLReauthenticator: NSObject {

  private var signInModalVC: NYPLAccountSignInViewController?

  /// Re-authenticates the user. This may involve presenting the sign-in
  /// modal UI or not, depending on the sign-in business logic.
  ///
  /// - Parameters:
  ///   - user: The current user.
  ///   - usingExistingCredentials: Use the existing credentials for `user`.
  ///   - authenticationCompletion: Code to run after the authentication
  ///   flow completes.
  /// - Returns: `true` if an authentication flow was started to refresh the
  /// credentials, `false` otherwise.
  @objc func authenticateIfNeeded(_ user: NYPLUserAccount,
                                  usingExistingCredentials: Bool,
                                  authenticationCompletion: (()-> Void)?) {
    NYPLMainThreadRun.asyncIfNeeded {
      let vc = NYPLAccountSignInViewController()
      self.signInModalVC = vc
      vc.forceEditability = true
      vc.presentIfNeeded(usingExistingCredentials: usingExistingCredentials) {
        authenticationCompletion?()
        self.signInModalVC = nil //break desired retain cycle
      }
    }
  }
}
