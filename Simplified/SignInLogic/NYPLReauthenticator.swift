//
//  NYPLReauthenticator.swift
//  Simplified
//
//  Created by Ettore Pasquini on 11/18/20.
//  Copyright © 2020 NYPL. All rights reserved.
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
  
  private var signInModalFactory: NYPLSignInModalFactory?
  
  @objc
  func authenticateIfNeeded(_ user: NYPLBasicAuthCredentialsProvider,
                            afterHTTPResponse response: URLResponse,
                            withProblemDocument problemDoc: NYPLProblemDocument?,
                            completion: ((_ isSignedIn: Bool)-> Void)?) {
    let hasCredentials = user.hasCredentials()
    let loginRequired = user.requiresUserAuthentication
    let serverNeedsRefresh = response.indicatesAuthenticationNeedsRefresh(with: problemDoc)
    
    if serverNeedsRefresh || (!hasCredentials && loginRequired) {
      authenticateIfNeeded(usingExistingCredentials: hasCredentials,
                           forceEditability: true,
                           completion: completion)
    }
  }
  
  /// Refresh authentication credentials if needed. This may result in a
  /// modal sign-in UI being presented to the user.
  ///
  /// - Parameter completion: Called at the end of the authentication process.
  @objc
  func refreshAuthentication(completion: ((_ isSignedIn: Bool) -> Void)?) {
    authenticateIfNeeded(usingExistingCredentials: false,
                         forceEditability: false,
                         completion: completion)
  }
  
  /// Re-authenticates the user. This may involve presenting the sign-in
  /// modal UI or not, depending on the sign-in business logic.
  ///
  /// - Parameters:
  ///   - usingExistingCredentials: Use the existing credentials.
  ///   - completion: Code to run after the authentication flow completes.
  @objc
  func authenticateIfNeeded(usingExistingCredentials: Bool,
                            completion: ((_ isSignedIn: Bool)-> Void)?) {
    authenticateIfNeeded(usingExistingCredentials: usingExistingCredentials,
                         forceEditability: true,
                         completion: completion)
  }
  
  private func authenticateIfNeeded(usingExistingCredentials: Bool,
                                    forceEditability: Bool,
                                    completion: ((_ isSignedIn: Bool)-> Void)?) {
    NYPLMainThreadRun.asyncIfNeeded { [self] in
      signInModalFactory = NYPLSignInModalFactory(
        usingExistingCredentials: usingExistingCredentials,
        forceEditability: forceEditability,
        modalCompletion: completion)
      
      signInModalFactory?.refreshAuthentication()
    }
  }
}
