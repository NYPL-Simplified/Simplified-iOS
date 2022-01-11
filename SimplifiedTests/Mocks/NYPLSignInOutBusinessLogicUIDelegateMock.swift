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
  func businessLogicWillSignOut(_ businessLogic: NYPLSignInBusinessLogic) {
  }

  func businessLogic(_ logic: NYPLSignInBusinessLogic,
                     didEncounterSignOutError error: Error?,
                     withHTTPStatusCode httpStatusCode: Int) {
  }

  func businessLogicDidFinishDeauthorizing(_ logic: NYPLSignInBusinessLogic) {
  }

  var context = "Unit Tests Context"

  func businessLogicWillSignIn(_ businessLogic: NYPLSignInBusinessLogic) {
  }

  func businessLogicDidCompleteSignIn(_ businessLogic: NYPLSignInBusinessLogic) {
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

  var username: String? = "username"

  var pin: String? = "pin"

  var usernameTextField: UITextField? = nil

  var PINTextField: UITextField? = nil

  var forceEditability: Bool = false
}
