//
//  NYPLBasicAuth.swift
//  Simplified
//
//  Created by Jacek Szyja on 02/07/2020.
//  Copyright © 2020 NYPL. All rights reserved.
//

import Foundation

/// Defines the interface required by the various pieces of the sign-in logic
/// to obtain the credentials for performing basic authentication.
@objc protocol NYPLBasicAuthCredentialsProvider: NSObjectProtocol {
  var username: String? {get}
  var pin: String? {get}
}

@objc class NYPLBasicAuth: NSObject {
  typealias BasicAuthCompletionHandler = (URLSession.AuthChallengeDisposition, URLCredential?) -> Void

  /// The object providing the credentials to respond to the authentication
  /// challenge.
  private var credentialsProvider: NYPLBasicAuthCredentialsProvider

  @objc(initWithCredentialsProvider:)
  init(credentialsProvider: NYPLBasicAuthCredentialsProvider) {
    self.credentialsProvider = credentialsProvider
    super.init()
  }

  /// Responds to the authentication challenge synchronously.
  /// - Parameters:
  ///   - challenge: The authentication challenge to respond to.
  ///   - completion: Always called, synchronously.
  @objc func handleChallenge(_ challenge: URLAuthenticationChallenge,
                             completion: BasicAuthCompletionHandler)
  {
    switch challenge.protectionSpace.authenticationMethod {
    case NSURLAuthenticationMethodHTTPBasic:
      guard
        let username = credentialsProvider.username,
        let password = credentialsProvider.pin,
        challenge.previousFailureCount == 0 else {
          completion(.cancelAuthenticationChallenge, nil)
          return
      }

      let credentials = URLCredential(user: username,
                                      password: password,
                                      persistence: .forSession)
      completion(.useCredential, credentials)

    case NSURLAuthenticationMethodServerTrust:
      completion(.performDefaultHandling, nil)

    default:
      completion(.rejectProtectionSpace, nil)
    }
  }
}
