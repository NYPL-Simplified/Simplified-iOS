//
//  NYPLOAuthTokenRefresher.swift
//  Simplified
//
//  Created by Ettore Pasquini on 3/29/22.
//  Copyright © 2022 NYPL. All rights reserved.
//

import Foundation
import NYPLUtilities

/// The class refreshes the OAuth token at the given URL and stores it locally
/// as well as in the given token provider.
///
/// Requests to refresh the token are serial in respect to one another.
class NYPLOAuthTokenRefresher {
  private let urlSession: URLSession
  private let tokenRefreshURL: URL
  private let serialQueue: DispatchQueue
  private let oauthTokenSetter: NYPLOAuthTokenSource

  var currentToken: NYPLOAuthAccessToken? {
    didSet {
      guard let token = currentToken?.accessToken else {
        return
      }

      oauthTokenSetter.setAuthToken(token)
    }
  }

  /// The threshold under which we will submit a request for a new token, even
  /// if the current token is not strictly expired yet. This is to avoid using
  /// a token that's not expired *right now* but that it is going to expire by
  /// the time it reaches the server.
  private let expirationThreshold: TimeInterval = 50.0

  /// Designated initializer
  /// - Parameters:
  ///   - refreshURL: The URL to be used to obtain a new token.
  ///   - oauthTokenSetter: The object that will be storing the token.
  ///   - urlSession: The URLSession that will execute the request. This
  ///   urlSession needs to be able to handle the authentication necessary
  ///   to obtain a new token.
  init(refreshURL: URL, oauthTokenSetter: NYPLOAuthTokenSource, urlSession: URLSession) {
    tokenRefreshURL = refreshURL
    self.oauthTokenSetter = oauthTokenSetter
    self.urlSession = urlSession
    serialQueue = DispatchQueue(label: "nypl_refresh_oauth_token_queue",
                                qos: .userInitiated,
                                target: DispatchQueue.global(qos: .userInitiated))
  }

  /// Submits a request to refresh the current token.
  ///
  /// Requests are submitted to a private serial queue, and one request will
  /// actually be executed when the previous has received a response from the
  /// server.
  /// - Parameter completion: The completion handler always called at the end.
  func refreshIfNeeded(completion: @escaping (_ result: NYPLResult<NYPLOAuthAccessToken>) -> Void) {
    guard let currentToken = currentToken else {
      serialQueue.async { [weak self] in
        guard let self = self else { return }
        let result = self.refreshSync()
        completion(result)
      }
      return
    }

    let now = Date()
    if currentToken.expiration < now.addingTimeInterval(-expirationThreshold) {
      serialQueue.async { [weak self] in
        guard let self = self else { return }
        let result = self.refreshSync()
        completion(result)
      }
      return
    }

    completion(.success(currentToken, nil))
  }

  /// - Note: Submitting a request to the token refresh URL will always
  /// return a new fresh token no matter if it was requested before the
  /// expiration time or not. The only exception to this behavior is if
  /// we submit 2 refresh requests within  60 seconds of each other. In
  /// that case the server the 2nd time returns the same token that was
  /// created within 60 seconds.
  private func refreshSync() -> NYPLResult<NYPLOAuthAccessToken> {
    Log.info(#file, "Refreshing OAuth Client Credentials token...")
    let refreshStartDate = Date()
    let req = URLRequest(url: tokenRefreshURL)
    let (responseData, response, error) = urlSession.synchronouslyExecute(req)

    let logMetadata: [String: Any] = [
      "request": req.loggableString,
      "responseData is nil?": (responseData == nil)
    ]

    if let error = error {
      NYPLErrorLogger.logNetworkError(error,
                                      summary: "OAuth Client Credentials token refresh completed with error",
                                      request: req,
                                      response: response,
                                      metadata: logMetadata)
      return .failure(error as NYPLUserFriendlyError, response)
    }

    guard let responseData = responseData else {
      return fail(for: req, response: response, metadata: logMetadata)
    }

    guard
      let httpResponse = response as? HTTPURLResponse,
      httpResponse.isSuccess()
    else {
      guard let problemDoc = try? NYPLProblemDocument.fromData(responseData) else {
        return fail(for: req, response: response, metadata: logMetadata)
      }

      let err = NSError.makeFromProblemDocument(
        problemDoc,
        domain: "Oauth Client Credentials token refresh failure",
        code: NYPLErrorCode.responseFail.rawValue,
        userInfo: [NSError.httpResponseKey: response ?? "N/A"])

      NYPLErrorLogger.logNetworkError(err, code: .responseFail,
                                      summary: "OAuth Client Credentials token refresh failure",
                                      request: req,
                                      response: response,
                                      metadata: logMetadata)
      return .failure(err, response)
    }

    guard let token = NYPLOAuthAccessToken.fromData(responseData) else {
      NYPLErrorLogger.logNetworkError(code: NYPLErrorCode.authDataParseFail,
                                      summary: "OAuth Client Credentials token parse error",
                                      request: req,
                                      response: response,
                                      metadata: logMetadata)
      let err = NSError(domain: "OAuth Client Credentials token parse error",
                        code: NYPLErrorCode.authDataParseFail.rawValue,
                        userInfo: [
                          NSLocalizedDescriptionKey:
                            NSLocalizedString("Unable to parse sign-in token",
                                              comment: "Error message for when the OAuth Client Credentials token parsing fails."),
                          NSLocalizedRecoverySuggestionErrorKey:
                            NSLocalizedString("Try force-quitting the app and repeat the sign-in process.",
                                              comment: "Recovery instructions for when the URL to sign in is missing"),
                          NSError.httpResponseKey: httpResponse])
      return .failure(err, httpResponse)
    }

    self.currentToken = token
    let elapsed = Date().timeIntervalSince(refreshStartDate)
    Log.info(#file, "OAuth Client Credentials token refresh complete. Elapsed time: \(elapsed) sec")

    return .success(token, httpResponse)
  }

  private func fail(for request: URLRequest,
                    response: URLResponse?,
                    metadata: [String: Any]) -> NYPLResult<NYPLOAuthAccessToken> {
    let err = makeGenericError(for: request, response: response, metadata: metadata)
    return .failure(err, response)
  }

  private func makeGenericError(for request: URLRequest,
                                response: URLResponse?,
                                metadata: [String: Any]) -> NSError {
    var logMetadata = metadata
    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
    logMetadata[NSLocalizedDescriptionKey] = NSError.makeGenericServerErrorMessage(
      forHTTPStatus: statusCode)
    NYPLErrorLogger.logNetworkError(code: NYPLErrorCode.responseFail,
                                    summary: "OAuth Client Credentials token refresh failure: no data",
                                    request: request,
                                    response: response,
                                    metadata: logMetadata)
    logMetadata[NSError.httpResponseKey] = response
    let err = NSError(domain: "Client Credentials OAuth Token refresh failure: no data",
                      code: NYPLErrorCode.responseFail.rawValue,
                      userInfo: logMetadata)
    return err
  }
}
