//
//  NYPLNetworkExecutor.swift
//  SimplyE
//
//  Created by Ettore Pasquini on 3/19/20.
//  Copyright © 2020 NYPL. All rights reserved.
//

import Foundation
import NYPLUtilities

/// Use this enum to express either-or semantics in a result.
enum NYPLResult<SuccessInfo> {
  case success(SuccessInfo, URLResponse?)
  case failure(NYPLUserFriendlyError, URLResponse?)
}

/// A class that is capable of executing network requests in a thread-safe way.
/// This class implements caching according to server response caching headers,
/// but can also be configured to have a fallback mechanism to cache responses
/// that lack a sufficient set of caching headers. This fallback cache attempts
/// to use the value found in the `max-age` directive of the `Cache-Control`
/// header if present, otherwise defaults to 3 hours.
///
/// The cache lives on both memory and disk.
@objc class NYPLNetworkExecutor: NSObject {
  private let urlSession: URLSession

  /// The delegate of the URLSession.
  private let responder: NYPLNetworkResponder

  /// Designated initializer.
  /// - Parameter credentialsSource: The object responsible with providing credentials.
  /// - Parameter cachingStrategy: The strategy to cache responses with.
  /// - Parameter waitsForConnectivity: if `false`, a request submitted when
  /// there's no internet will fail immediately.
  /// - Parameter delegateQueue: The queue where callbacks will be called.
  @objc init(credentialsSource: NYPLBasicAuthCredentialsProvider & NYPLOAuthTokenSource,
             cachingStrategy: NYPLCachingStrategy,
             waitsForConnectivity: Bool = true,
             delegateQueue: OperationQueue? = nil) {
    self.responder = NYPLNetworkResponder(credentialsSource: credentialsSource,
                                          useFallbackCaching: cachingStrategy == .fallback)

    let config = NYPLCaching.makeURLSessionConfiguration(
      caching: cachingStrategy,
      waitsForConnectivity: waitsForConnectivity,
      requestTimeout: NYPLNetworkExecutor.defaultRequestTimeout)
    self.urlSession = URLSession(configuration: config,
                                 delegate: self.responder,
                                 delegateQueue: delegateQueue)
    super.init()
  }

  deinit {
    urlSession.finishTasksAndInvalidate()
  }

  @objc func clearCache() {
    urlSession.configuration.urlCache?.removeAllCachedResponses()
  }

  /// A shared generic executor with enabled fallback caching.
  @objc static let shared = NYPLNetworkExecutor(credentialsSource: NYPLUserAccount.sharedAccount(),
                                                cachingStrategy: .fallback)

  @objc func request(for url: URL) -> URLRequest {
    return request(for: url, cachePolicy: nil)
  }

  func request(for url: URL,
               cachePolicy: URLRequest.CachePolicy? = nil,
               additionalHeaders: [String: String]? = nil,
               httpMethod: String = "GET",
               httpBody: Data? = nil) -> URLRequest {
    let cachePolicy = cachePolicy ?? urlSession.configuration.requestCachePolicy
    var request = URLRequest(url: url, cachePolicy: cachePolicy)
    request.httpMethod = httpMethod
    request.httpBody = httpBody

    if let authToken = responder.credentialsSource.authToken {
      let headers = [
        "Authorization" : "Bearer \(authToken)",
        "Content-Type" : "application/json"
      ]

      headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
    } else {
      Log.debug(#function, "Not using Bearer token...")
    }

    additionalHeaders?.forEach { (key: String, value: String) in
      request.setValue(value, forHTTPHeaderField: key)
    }

    return request
  }
}

extension NYPLNetworkExecutor: NYPLHTTPRequestExecuting {
  /// Performs a GET request using the specified URL
  /// - Parameters:
  ///   - reqURL: URL of the resource to GET.
  ///   - cachePolicy: If nil, the policy set up by the executor will be used.
  ///   - completion: Always called when the resource is either fetched from
  /// the network or from the cache.
  func GET(_ reqURL: URL,
           cachePolicy: URLRequest.CachePolicy? = nil,
           completion: @escaping (_ result: NYPLResult<Data>) -> Void) {
    let req = request(for: reqURL, cachePolicy: cachePolicy)
    executeRequest(req, completion: completion)
  }

  func POST(_ reqURL: URL,
            additionalHeaders: [String: String]? = nil,
            httpBody: Data? = nil,
            completion: @escaping (_ result: NYPLResult<Data>) -> Void) {
    let req = request(for: reqURL,
                      additionalHeaders: additionalHeaders,
                      httpMethod: "POST",
                      httpBody: httpBody)
    executeRequest(req, completion: completion)
  }

  /// Performs a DELETE request at the specified URL.
  /// - Parameters:
  ///   - reqURL: URL of the resource to DELETE.
  ///   - completion: Always called after the server responds.
  func DELETE(_ reqURL: URL,
              completion: @escaping (_ result: NYPLResult<Data>) -> Void) {
    let req = request(for: reqURL, httpMethod: "DELETE")
    executeRequest(req, completion: completion)
  }
}

extension NYPLNetworkExecutor: NYPLOAuthTokenFetching {

  private var oauthTokenRefresher: NYPLOAuthTokenRefresher? {
    return responder.oauthTokenRefresher
  }

  /// Fetches a short lived OAuth token and communicates the intention to use
  /// that as authentication mechanism.
  ///
  /// - Parameters:
  ///   - url: The URL to fetch the OAuth token at.
  ///   - completion: Closure to invoke once the token call has completed.
  func fetchAndStoreShortLivedOAuthToken(at url: URL,
                                         completion: @escaping (_ result: NYPLResult<NYPLOAuthAccessToken>) -> Void) {
    if oauthTokenRefresher == nil {
      responder.oauthTokenRefresher = NYPLOAuthTokenRefresher(
        refreshURL: url,
        oauthTokenSetter: responder.credentialsSource,
        urlSession: urlSession)
    }

    DispatchQueue.global(qos: .userInitiated).async {
      self.oauthTokenRefresher!.refreshIfNeeded(completion: completion)
    }
  }

  /// Resets internal state that's related to a specific library.
  ///
  /// - Important: this leaves network cache unaltered.
  func resetLibrarySpecificInfo() {
    responder.oauthTokenRefresher = nil
    NYPLNetworkExecutor.shared.responder.oauthTokenRefresher = nil
  }
}

extension NYPLNetworkExecutor: NYPLRequestExecuting {

  /// Executes a given request.
  /// - Parameters:
  ///   - req: The request to perform.
  ///   - completion: Always called when the resource is either fetched from
  /// the network or from the cache.
  /// - Returns: The task carrying out the given request. Note that this task
  /// may not be started yet after being returned.
  @discardableResult
  func executeRequest(_ req: URLRequest,
                      completion: @escaping (_: NYPLResult<Data>) -> Void) -> URLSessionDataTask {

    let task = self.urlSession.dataTask(with: req)
    responder.addCompletion(completion, taskID: task.taskIdentifier)

    let startTask = {
      Log.info(#file, "Task \(task.taskIdentifier): starting request \(req.loggableString)")
      task.resume()
    }

    if responder.credentialsSource.hasOAuthClientCredentials(),
       let tokenRefreshURL = responder.credentialsSource.oauthTokenRefreshURL {

      fetchAndStoreShortLivedOAuthToken(at: tokenRefreshURL) { result in
        startTask()
      }
    } else {
      startTask()
    }

    return task
  }
}

// MARK: -  Objective-C compatibility
extension NYPLNetworkExecutor: NYPLHTTPRequestExecutingBasic {

  /// Performs a GET request using the specified URL, adding authentication
  /// headers if needed.
  /// - Parameters:
  ///   - reqURL: URL of the resource to GET.
  ///   - completion: Always called when the resource is either fetched from
  ///   the network or from the cache. The `result` and `error` parameters are
  ///   guaranteed to be mutually exclusive.
  @discardableResult @objc
  func GET(_ reqURL: URL,
           cachePolicy: NSURLRequest.CachePolicy = .useProtocolCachePolicy,
           completion: @escaping (_ result: Data?, _ response: URLResponse?,  _ error: Error?) -> Void) -> URLSessionDataTask {
    let req = request(for: reqURL, cachePolicy: cachePolicy)
    let completionWrapper: (_ result: NYPLResult<Data>) -> Void = { result in
      switch result {
      case let .success(data, response): completion(data, response, nil)
      case let .failure(error, response): completion(nil, response, error)
      }
    }
    return executeRequest(req, completion: completionWrapper)
  }

  /// Performs a PUT request using the specified URL, adding authentication
  /// headers if needed.
  /// - Parameters:
  ///   - reqURL: URL of the resource to PUT.
  ///   - completion: Always called when the resource is either fetched from
  ///   the network or from the cache. The `result` and `error` parameters are
  ///   guaranteed to be mutually exclusive.
  @objc
  func PUT(_ reqURL: URL,
           additionalHeaders: [String: String]? = nil,
           httpBody: Data? = nil,
           completion: @escaping (_ result: Data?, _ response: URLResponse?,  _ error: Error?) -> Void) {
    let req = request(for: reqURL,
                      additionalHeaders: additionalHeaders,
                      httpMethod: "PUT",
                      httpBody: httpBody)
    let completionWrapper: (_ result: NYPLResult<Data>) -> Void = { result in
      switch result {
      case let .success(data, response): completion(data, response, nil)
      case let .failure(error, response): completion(nil, response, error)
      }
    }
    executeRequest(req, completion: completionWrapper)
  }
    
  /// Performs a POST request using the specified request, adding authentication
  /// headers if needed.
  /// - Parameters:
  ///   - request: Request to be posted..
  ///   - completion: Always called when the api call either returns or times
  ///   out. The `result` and `error` parameters are
  ///   guaranteed to be mutually exclusive.
  @objc
  func POST(_ request: URLRequest,
            completion: ((_ result: Data?, _ response: URLResponse?,  _ error: Error?) -> Void)?) {
      
    if (request.httpMethod != "POST") {
      var newRequest = request
      newRequest.httpMethod = "POST"
      return POST(newRequest, completion: completion)
    }
      
    let completionWrapper: (_ result: NYPLResult<Data>) -> Void = { result in
      switch result {
        case let .success(data, response): completion?(data, response, nil)
        case let .failure(error, response): completion?(nil, response, error)
      }
    }
    
    executeRequest(request, completion: completionWrapper)
  }
}
