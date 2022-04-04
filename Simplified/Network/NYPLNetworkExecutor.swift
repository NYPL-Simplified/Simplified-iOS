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
  /// - Parameter credentialsProvider: The object responsible with providing credentials.
  /// - Parameter cachingStrategy: The strategy to cache responses with.
  /// - Parameter delegateQueue: The queue where callbacks will be called.
  @objc init(credentialsProvider: NYPLBasicAuthCredentialsProvider & NYPLOAuthTokenProvider,
             cachingStrategy: NYPLCachingStrategy,
             delegateQueue: OperationQueue? = nil) {
    self.responder = NYPLNetworkResponder(credentialsProvider: credentialsProvider,
                                          useFallbackCaching: cachingStrategy == .fallback)

    let config = NYPLCaching.makeURLSessionConfiguration(
      caching: cachingStrategy,
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
  @objc static let shared = NYPLNetworkExecutor(credentialsProvider: NYPLUserAccount.sharedAccount(),
                                                cachingStrategy: .fallback)

  @objc func request(for url: URL) -> URLRequest {
    var urlRequest = URLRequest(url: url,
                                cachePolicy: urlSession.configuration.requestCachePolicy)

    if let authToken = responder.credentialsProvider.authToken {
      let headers = [
        "Authorization" : "Bearer \(authToken)",
        "Content-Type" : "application/json"
      ]

      headers.forEach { urlRequest.setValue($0.value, forHTTPHeaderField: $0.key) }
    }

    return urlRequest
  }

  /// Performs a GET request using the specified URL
  /// - Parameters:
  ///   - reqURL: URL of the resource to GET.
  ///   - completion: Always called when the resource is either fetched from
  /// the network or from the cache.
  func GET(_ reqURL: URL,
           completion: @escaping (_ result: NYPLResult<Data>) -> Void) {
    let req = request(for: reqURL)
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
        oauthTokenProvider: responder.credentialsProvider,
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

    if responder.credentialsProvider.hasOAuthClientCredentials(),
       let tokenRefreshURL = responder.credentialsProvider.oauthTokenRefreshURL {

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
extension NYPLNetworkExecutor: NYPLRequestExecutingObjC {

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
    var req = request(for: reqURL)
    req.cachePolicy = cachePolicy
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
           completion: @escaping (_ result: Data?, _ response: URLResponse?,  _ error: Error?) -> Void) {
    var req = request(for: reqURL)
    req.httpMethod = "PUT"
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
