//
//  URLResponse+NYPLAuthentication.swift
//  Simplified
//
//  Created by Ettore Pasquini on 11/18/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

extension URLResponse {

  /// Attempts to determine if the response indicates that the user's
  /// credentials are expired or invalid.
  ///
  /// The idea is that if the user was authenticated and an error is returned,
  /// this may indicate that the credentials that were used in the request
  /// are no longer valid. The problem document, if available, is the
  /// primary source of truth.
  ///
  /// You could use this api even when the user was not authenticated to begin
  /// with, but in that case you'd already know the reason of the error.
  ///
  /// - Parameter problemDoc: The problem document returned by the server.
  /// - Returns: `true` if the response or problem document indicate that the
  /// authentication needs to be refreshed.
  @objc(indicatesAuthenticationNeedsRefresh:)
  func indicatesAuthenticationNeedsRefresh(with problemDoc: NYPLProblemDocument?) -> Bool {
    return isProblemDocument() && problemDoc?.type == NYPLProblemDocument.TypeInvalidCredentials 
  }
}

extension HTTPURLResponse {
  @objc(indicatesAuthenticationNeedsRefresh:)
  override func indicatesAuthenticationNeedsRefresh(with problemDoc: NYPLProblemDocument?) -> Bool {

    if super.indicatesAuthenticationNeedsRefresh(with: problemDoc) {
      return true
    }

    if statusCode == 401 {
      return true
    }

    if !isSuccess() && mimeType == "application/vnd.opds.authentication.v1.0+json" {
      return true
    }

    return false
  }
}
