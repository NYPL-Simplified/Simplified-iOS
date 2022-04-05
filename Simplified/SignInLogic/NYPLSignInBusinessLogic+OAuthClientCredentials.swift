//
//  NYPLSignInBusinessLogic+OAuthClientCredentials.swift
//  Simplified
//
//  Created by Ettore Pasquini on 3/21/22.
//  Copyright © 2022 NYPL. All rights reserved.
//

import Foundation
import NYPLUtilities

extension NYPLSignInBusinessLogic {

  func oauthClientCredentialsLogin() {
    guard
      let libraryAuthDetails = libraryAccount?.details?.defaultAuth,
      let url = libraryAuthDetails.oauthIntermediaryUrl
    else {
      let error = NSError(domain: "Unable to create URL for signing in via OAuth Client Credentials",
                          code: NYPLErrorCode.noURL.rawValue,
                          userInfo: [
                            NSLocalizedDescriptionKey:
                              NSLocalizedString("Unable to contact the server because the URL for signing in is missing.",
                                                comment: "Error message for when the library profile url is missing from the authentication document the server provided."),
                            NSLocalizedRecoverySuggestionErrorKey:
                              NSLocalizedString("Try force-quitting the app and repeat the sign-in process.",
                                                comment: "Recovery instructions for when the URL to sign in is missing")])
      self.handleNetworkError(error,
                              loggingContext: [
                                "Context": "OauthClientCredentials",
                                "library.oauthIntermediaryUrl":
                                  libraryAccount?.details?.defaultAuth?.oauthIntermediaryUrl ?? "N/A"
                              ])
      return
    }

    var attemptedUsername: String? = nil
    NYPLMainThreadRun.asyncIfNeeded {
      attemptedUsername = self.uiDelegate?.username?.md5hex()
    }

    networker.fetchAndStoreShortLivedOAuthToken(at: url) { [weak self] result in
      guard let self = self else {
        return
      }

      let loggingContext: [String: Any] = [
        "Request URL": url,
        "Attempted Barcode": attemptedUsername ?? "N/A"
      ]

      switch result {
      case .success(let accessToken, _):
        self.authToken = accessToken.accessToken
        self.validateCredentials()
      case .failure(let errorWithProblemDoc, let response):
        self.handleNetworkError(errorWithProblemDoc as NSError,
                                response: response,
                                loggingContext: loggingContext)
      }
    }
  }
}
