//
//  NYPLSignInOutBusinessLogicUIDelegateMock.swift
//  Simplified
//
//  Created by Ettore Pasquini on 2/3/21.
//  Copyright © 2021 NYPL. All rights reserved.
//

import Foundation
@testable import SimplyE

class NYPLSignInOutBusinessLogicUIDelegateMock: NSObject, NYPLSignInOutBusinessLogicUIDelegate {

  // MARK: - NYPLSignInOutBusinessLogicUIDelegate

  func businessLogicWillSignOut(_ businessLogic: NYPLSignInBusinessLogic) {
  }

  func businessLogic(_ logic: NYPLSignInBusinessLogic,
                     didEncounterSignOutError error: Error?,
                     withHTTPStatusCode httpStatusCode: Int) {
  }

  func businessLogicDidFinishDeauthorizing(_ logic: NYPLSignInBusinessLogic) {
  }

  // MARK: - NYPLSignInBusinessLogicUIDelegate

  var context = "Unit Tests Context"

  func businessLogicWillSignIn(_ businessLogic: NYPLSignInBusinessLogic) {
  }

  func businessLogicDidSignIn(_ businessLogic: NYPLSignInBusinessLogic) {
  }

  func businessLogic(_ logic: NYPLSignInBusinessLogic,
                     didEncounterValidationError error: Error?,
                     userFriendlyErrorTitle title: String?,
                     andMessage message: String?) {
  }

  func dismiss(animated flag: Bool, completion: (() -> Void)?) {
    completion?()
  }

  func present(_ viewControllerToPresent: UIViewController,
               animated flag: Bool,
               completion: (() -> Void)?) {
    completion?()
  }

  // MARK: - NYPLBasicAuthCredentialsProvider

  var username: String? = "username"

  var pin: String? = "pin"

  var requiresUserAuthentication: Bool {
    return true
  }

  func hasCredentials() -> Bool {
    return false
  }

  // MARK: - NYPLUserAccountInputProvider

  var usernameTextField: UITextField? = nil

  var PINTextField: UITextField? = nil

  var forceEditability: Bool = false

  // MARK: - NYPLOAuthTokenProvider

  var authToken: String? {
    return "fake token"
  }

  func setAuthToken(_ token: String) {
  }

  func hasOAuthClientCredentials() -> Bool {
    return false
  }

  var oauthTokenRefreshURL: URL? {
    return nil
  }
}
