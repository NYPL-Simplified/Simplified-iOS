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
  /// The context in which the UI delegate is operating in, such as in a modal
  /// sheet or a tab.
  var context: String {get}

  /// In case we need to show an error message to the user.
  func displayErrorMessage(_ msg: String?)

  /// Notifies the delegate that the process of signing in is about to begin.
  /// - Parameter businessLogic: The business logic in charge of signing in.
  func businessLogicWillSignIn(_ businessLogic: NYPLSignInBusinessLogic)

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

  // TODO: SIMPLY-2510 rename this from point of view of businesslogic,
  // and perform logging inside business logic rather than delegate
  func alertUser(ofValidationError: Error?,
                 problemDocData: Data?,
                 response: URLResponse?,
                 loggingContext: [String: Any])

  @objc(dismissViewControllerAnimated:completion:)
  func dismiss(animated flag: Bool, completion: (() -> Void)?)

  @objc(presentViewController:animated:completion:)
  func present(_ viewControllerToPresent: UIViewController,
               animated flag: Bool,
               completion: (() -> Void)?)

}
