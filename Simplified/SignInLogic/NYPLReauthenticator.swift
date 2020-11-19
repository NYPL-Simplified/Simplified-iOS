//
//  NYPLReauthenticator.swift
//  Simplified
//
//  Created by Ettore Pasquini on 11/18/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

@objc class NYPLReauthenticator: NSObject {

  /// Determines if the current authentication state has changed based on
  /// this response metadata and the returned data.
  ///
  /// - Parameters:
  ///   - user: The current user.
  ///   - response: The response to inspect.
  ///   - responseData: The data returned by the server for this response.
  ///   - responseError: Any error returned by URLSession or the like. If you
  ///   used `NYPLNetworkExecutor`, this should include the problem document
  ///   if the server sent it.
  ///   - authenticationPreflight: Code to run before starting the
  ///   authentication flow.
  ///   - authenticationCompletion: Code to run after the authentication
  ///   flow completes.
  /// - Returns: `true` if an authentication flow was started to refresh the
  /// credentials, `false` otherwise.
  @objc func authenticateUser(_ user: NYPLUserAccount,
                              ifNeededForResponse response: URLResponse,
                              responseData: Data?,
                              responseError: NSError?,
                              authenticationPreflight: (() -> Void)?,
                              authenticationCompletion: (()-> Void)?) -> Bool {
    let problemDoc: NYPLProblemDocument?
    if let problemDocFromError = responseError?.problemDocument {
      problemDoc = problemDocFromError
    } else if let responseData = responseData {
      problemDoc = try? NYPLProblemDocument.fromData(responseData)
    } else {
      problemDoc = nil
    }

    if response.indicatesAuthenticationNeedsRefresh(with: problemDoc) {
      authenticate(user: user,
                   preflight: authenticationPreflight,
                   completion: authenticationCompletion)
      return true
    }

    return false
  }

  private func authenticate(user: NYPLUserAccount,
                            preflight: (() -> Void)?,
                            completion: (()-> Void)?) {
    preflight?()
    NYPLAccountSignInViewController.requestCredentials(
      usingExisting: user.authDefinition?.authType == .basic,
      authorizeImmediately: user.authDefinition?.authType == .basic,
      completionHandler: completion ?? {})
  }
}
