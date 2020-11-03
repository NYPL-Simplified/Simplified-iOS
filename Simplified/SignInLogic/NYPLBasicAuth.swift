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
    switch challenge.protectionSpace.authenticationMethod {
    case NSURLAuthenticationMethodHTTPBasic:
      let account = NYPLUserAccount.sharedAccount()
      if let barcode = account.barcode, let pin = account.PIN {
        authCustomHandler(challenge: challenge,
                          completionHandler: completionHandler,
                          username: barcode,
                          password: pin)
      } else {
        completionHandler(.cancelAuthenticationChallenge, nil)
      }

    case NSURLAuthenticationMethodServerTrust:
      completionHandler(.performDefaultHandling, nil)

    default:
      completionHandler(.rejectProtectionSpace, nil)
    }
  }

  @objc static func authCustomHandler(challenge: URLAuthenticationChallenge!,
                                      completionHandler: @escaping BasicAuthCompletionHandler,
                                      username: String,
                                      password: String)
  {
    switch challenge.protectionSpace.authenticationMethod {
    case NSURLAuthenticationMethodHTTPBasic:
      if challenge.previousFailureCount == 0 {
        let credentials = URLCredential(user: username,
                                        password: password,
                                        persistence: .none)
        completionHandler(.useCredential, credentials)
      } else {
        completionHandler(.cancelAuthenticationChallenge, nil)
      }

    default:
      completionHandler(.rejectProtectionSpace, nil)
    }
  }
}
