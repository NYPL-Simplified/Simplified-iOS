//
//  NYPLSignInBusinessLogicUIDelegate.swift
//  Simplified
//
//  Created by Ettore Pasquini on 10/13/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

/// The functionalities on the UI that the sign-in business logic requires.
@objc protocol NYPLSignInBusinessLogicUIDelegate: NSObjectProtocol {
  /// The context in which the UI delegate is operating in.
  var context: String {get}

  /// In case we need to show an error message to the user.
  func displayErrorMessage(_ msg: String?)

  /// The current OAuth token if available.
  /// - TODO: SIMPLY-2510 Do not use, this is here only temporarily.
  var authToken: String? {get set}

  /// The current patron info if available.
  /// - TODO: SIMPLY-2510 Do not use, this is here only temporarily.
  var patron: [String: Any]? {get set}

  /// The business logic to validate the current credentials.
  /// - TODO: SIMPLY-2510 Do not use, this is here only temporarily.
  func validateCredentials()

  /// After signing in and authorizing for DRM successfully or not, the
  /// business logic will let the UI know the result by calling this method.
  /// - Parameters:
  ///   - success: Whether DRM authorization succeeded or not.
  ///   - error: The error that occurred, if any.
  ///   - errorMessage: A specific error message in case an `error` object is
  ///   missing.
  func finalizeSignIn(forDRMAuthorization success: Bool,
                      error: NSError?,
                      errorMessage: String?)

  @objc(dismissViewControllerAnimated:completion:)
  func dismiss(animated flag: Bool, completion: (() -> Void)?)

  @objc(presentViewController:animated:completion:)
  func present(_ viewControllerToPresent: UIViewController,
               animated flag: Bool,
               completion: (() -> Void)?)

}
