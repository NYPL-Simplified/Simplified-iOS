//
//  NYPLSignInBusinessLogicUIDelegate.swift
//  Simplified
//
//  Created by Ettore Pasquini on 10/13/20.
//  Copyright © 2020 NYPL. All rights reserved.
//

import UIKit

/// The functionalities on the UI that the sign-in business logic requires.
@objc protocol NYPLSignInBusinessLogicUIDelegate: NYPLBasicAuthCredentialsProvider, NYPLOAuthTokenSource, NYPLUserAccountInputProvider {
  /// The context in which the UI delegate is operating in, such as in a modal
  /// sheet or a tab.
  /// - Note: This should not be derived from a computation involving views,
  /// because it may be called outside of the main thread.
  var context: String {get}

  /// Notifies the delegate that the process of signing in is about to begin.
  /// - Note: This is always called on the main thread.
  /// - Parameter businessLogic: The business logic in charge of signing in.
  func businessLogicWillSignIn(_ businessLogic: NYPLSignInBusinessLogic)

  /// Notifies the delegate that the process of signing in has completed
  /// successfully.
  /// - Note: This is always called on the main thread.
  /// - Parameter businessLogic: The business logic in charge of signing in.
  func businessLogicDidSignIn(_ businessLogic: NYPLSignInBusinessLogic)

  /// Notifies the delegate that an error happened during sign in,
  /// providing (if available) a user-friendly message and title, possibly
  /// derived from the server response.
  /// - Parameters:
  ///   - logic: A reference to the business logic that handled the sign-in.
  ///   - error: The instance of the error if available.
  ///   - title: A user friendly title derived from the problem document
  ///   if possible.
  ///   - message: A user friendly message derived from the problem document
  ///   if possible.
  func businessLogic(_ logic: NYPLSignInBusinessLogic,
                     didEncounterValidationError error: Error?,
                     userFriendlyErrorTitle title: String?,
                     andMessage message: String?)

  @objc(dismissViewControllerAnimated:completion:)
  func dismiss(animated flag: Bool, completion: (() -> Void)?)

  @objc(presentViewController:animated:completion:)
  func present(_ viewControllerToPresent: UIViewController,
               animated flag: Bool,
               completion: (() -> Void)?)
}

@objc protocol NYPLSignInOutBusinessLogicUIDelegate: NYPLSignInBusinessLogicUIDelegate {
  /// Notifies the delegate that the process of signing out is about to begin.
  /// - Note: This is always called on the main thread.
  /// - Parameter businessLogic: The business logic in charge of signing in/out.
  func businessLogicWillSignOut(_ businessLogic: NYPLSignInBusinessLogic)

  /// Notifies the delegate that an error happened during sign out.
  /// - Parameters:
  ///   - logic: A reference to the business logic that handled the sign-out process.
  ///   - error: The instance of the error if available.
  ///   - httpStatusCode: The HTTP status code for the sign-out request.
  func businessLogic(_ logic: NYPLSignInBusinessLogic,
                     didEncounterSignOutError error: Error?,
                     withHTTPStatusCode httpStatusCode: Int)

  /// Notifies the delegate that deauthorization has completed.
  /// - Parameter logic: The business logic in charge of signing out.
  func businessLogicDidFinishDeauthorizing(_ logic: NYPLSignInBusinessLogic)
}
