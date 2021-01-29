//
//  NYPLBasicAuth.swift
//  Simplified
//
//  Created by Jacek Szyja on 02/07/2020.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

@objc class NYPLBasicAuth: NSObject {
  typealias BasicAuthCompletionHandler = (URLSession.AuthChallengeDisposition, URLCredential?) -> Void

  @objc static func authHandler(challenge: URLAuthenticationChallenge,
                                completionHandler: @escaping BasicAuthCompletionHandler)
  {
    let account = NYPLUserAccount.sharedAccount()
    authHandler(username: account.barcode, password: account.PIN,
                challenge: challenge, completionHandler: completionHandler)
  }

  static func authHandler(username: String?,
                          password: String?,
                          challenge: URLAuthenticationChallenge,
                          completionHandler: @escaping BasicAuthCompletionHandler)
  {
    switch challenge.protectionSpace.authenticationMethod {
    case NSURLAuthenticationMethodHTTPBasic:
      guard
        let username = username,
        let password = password,
        challenge.previousFailureCount == 0 else {
          completionHandler(.cancelAuthenticationChallenge, nil)
          return
      }

      let credentials = URLCredential(user: username,
                                      password: password,
                                      persistence: .none)
      completionHandler(.useCredential, credentials)

    case NSURLAuthenticationMethodServerTrust:
      completionHandler(.performDefaultHandling, nil)

    default:
      completionHandler(.rejectProtectionSpace, nil)
    }
  }
}
