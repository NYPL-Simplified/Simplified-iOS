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
    guard let request = makeRequestOauthCredentials() else {
      let error = NSError(domain: NYPLErrorLogger.clientDomain,
                          code: NYPLErrorCode.noURL.rawValue,
                          userInfo: [
                            NSLocalizedDescriptionKey:
                              NSLocalizedString("Unable to contact the server because the URL for signing in is missing.",
                                                comment: "Error message for when the library profile url is missing from the authentication document the server provided."),
                            NSLocalizedRecoverySuggestionErrorKey:
                              NSLocalizedString("Try force-quitting the app and repeat the sign-in process.",
                                                comment: "Recovery instructions for when the URL to sign in is missing")])
      self.handleNetworkError(error, loggingContext: ["Context": "OauthClientCredentials"])
      return
    }

    networker.executeRequest(request) { [weak self] result in
      guard let self = self else {
        return
      }

      let loggingContext: [String: Any] = [
        "Request": request.loggableString,
        "Attempted Barcode": self.uiDelegate?.username?.md5hex() ?? "N/A"
      ]

      switch result {
      case .success(let responseData, let response):
        self.handleOAuthClientCredentialsToken(responseData,
                                               response: response,
                                               loggingContext: loggingContext)
      case .failure(let errorWithProblemDoc, let response):
        self.handleNetworkError(errorWithProblemDoc as NSError,
                                response: response,
                                loggingContext: loggingContext)
      }
    }
  }

  private func handleOAuthClientCredentialsToken(_ responseData: Data,
                                                 response: URLResponse?,
                                                 loggingContext: [String: Any]) {
    guard let token = NYPLOAuthAccessToken.fromData(responseData) else {
      let err = NSError(domain: "OAuth Client Credentials token parse error",
                        code: NYPLErrorCode.authDataParseFail.rawValue,
                        userInfo: [
                          NSLocalizedDescriptionKey:
                            NSLocalizedString("Unable to parse sign-in token",
                                              comment: "Error message for when the OAuth Client Credentials token parsing fails."),
                          NSLocalizedRecoverySuggestionErrorKey:
                            NSLocalizedString("Try force-quitting the app and repeat the sign-in process.",
                                              comment: "Recovery instructions for when the URL to sign in is missing")])
      self.handleNetworkError(err,
                              response: response,
                              loggingContext: loggingContext)
      return
    }

    self.authToken = token.accessToken
    self.validateCredentials()
  }

  private func makeRequestOauthCredentials() -> URLRequest? {
    guard
      let libraryAuthDetails = libraryAccount?.details?.defaultAuth,
      let url = libraryAuthDetails.oauthIntermediaryUrl else {
        NYPLErrorLogger.logError(
          withCode: .noURL,
          summary: "Error: unable to create URL for signing in via OAuth Client Credentials",
          metadata: ["library.oauthIntermediaryUrl":
                      libraryAccount?.details?.defaultAuth?.oauthIntermediaryUrl ?? "N/A"])
        return nil
      }

    return URLRequest(url: url)
  }
}
