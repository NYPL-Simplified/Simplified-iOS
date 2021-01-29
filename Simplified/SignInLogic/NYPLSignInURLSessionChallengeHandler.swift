//
//  NYPLSignInURLSessionChallengeHandler.swift
//  Simplified
//
//  Created by Ettore Pasquini on 10/30/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

/**
 A class responsible for handling the authentication challenge initiated
 during the sign-in process.
 */
@objc class NYPLSignInURLSessionChallengeHandler: NSObject {
  @objc weak var uiDelegate: NYPLSignInUserProvidedCredentials?

  @objc(initWithUIDelegate:)
  init(uiDelegate: NYPLSignInUserProvidedCredentials?) {
    self.uiDelegate = uiDelegate
  }
}

// MARK:- URLSessionTaskDelegate

extension NYPLSignInURLSessionChallengeHandler: URLSessionTaskDelegate {
  @objc(URLSession:task:didReceiveChallenge:completionHandler:)
  func urlSession(_ session: URLSession,
                  task: URLSessionTask,
                  didReceive challenge: URLAuthenticationChallenge,
                  completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    NYPLMainThreadRun.asyncIfNeeded {
      NYPLBasicAuth.authHandler(username: self.uiDelegate?.username,
                                password: self.uiDelegate?.pin,
                                challenge: challenge,
                                completionHandler: completionHandler)
    }
  }
}
