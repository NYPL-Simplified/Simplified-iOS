//
//  NYPLNetworkExecutor.swift
//  SimplyE
//
//  Created by Ettore Pasquini on 3/19/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

/// Use this enum to express either-or semantics in a result.
enum NYPLResult<SuccessInfo> {
  case success(SuccessInfo, URLResponse?)
  case failure(NYPLUserFriendlyError, URLResponse?)
}

protocol NYPLRequestExecuting {
  /// Execute a given request.
  /// - Parameters:
  ///   - req: The request to perform.
  ///   - completion: Always called when the resource is either fetched from
  /// the network or from the cache.
  /// - Returns: The task issueing the given request.
  @discardableResult
  func executeRequest(_ req: URLRequest,
                      completion: @escaping (_: NYPLResult<Data>) -> Void) -> URLSessionDataTask

  var requestTimeout: TimeInterval {get}
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
  /// - Parameter credentialsProvider: The object responsible with providing cretdentials
  /// - Parameter cachingStrategy: The strategy to cache responses with.
  /// - Parameter delegateQueue: The queue where callbacks will be called.
  init(credentialsProvider: NYPLBasicAuthCredentialsProvider? = nil,
       cachingStrategy: NYPLCachingStrategy,
       delegateQueue: OperationQueue? = nil) {
    self.responder = NYPLNetworkResponder(credentialsProvider: credentialsProvider,
                                          useFallbackCaching: cachingStrategy == .fallback)

    let config = NYPLCaching.makeURLSessionConfiguration(caching: cachingStrategy)
    self.urlSession = URLSession(configuration: config,
                                 delegate: self.responder,
                                 delegateQueue: delegateQueue)
    super.init()
  }

  deinit {
    urlSession.finishTasksAndInvalidate()
  }

  /// A shared generic executor with enabled fallback caching.
  @objc static let shared = NYPLNetworkExecutor(cachingStrategy: .fallback)

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

extension NYPLNetworkExecutor: NYPLRequestExecuting {
  /// Executes a given request.
  /// - Parameters:
  ///   - req: The request to perform.
  ///   - completion: Always called when the resource is either fetched from
  /// the network or from the cache.
  /// - Returns: The task issueing the given request.
  @discardableResult
  func executeRequest(_ req: URLRequest,
           completion: @escaping (_: NYPLResult<Data>) -> Void) -> URLSessionDataTask {
    let task = urlSession.dataTask(with: req)
    responder.addCompletion(completion, taskID: task.taskIdentifier)
    Log.info(#file, "Task \(task.taskIdentifier): starting request \(req.loggableString)")
    task.resume()
    return task
  }

  var requestTimeout: TimeInterval {
    return urlSession.configuration.timeoutIntervalForRequest
  }
}

extension NYPLNetworkExecutor {
  func request(for url: URL) -> URLRequest {

    var urlRequest = URLRequest(url: url,
                                cachePolicy: urlSession.configuration.requestCachePolicy)

    if let authToken = NYPLUserAccount.sharedAccount().authToken {
      let headers = [
        "Authorization" : "Bearer \(authToken)",
        "Content-Type" : "application/json"
      ]

      headers.forEach { urlRequest.setValue($0.value, forHTTPHeaderField: $0.key) }
    }

    return urlRequest
  }

  @objc func clearCache() {
    urlSession.configuration.urlCache?.removeAllCachedResponses()
  }
}

// Objective-C compatibility
extension NYPLNetworkExecutor {
  @objc class func bearerAuthorized(request: URLRequest) -> URLRequest {
    let headers: [String: String]
    if let authToken = NYPLUserAccount.sharedAccount().authToken {
      headers = [
        "Authorization" : "Bearer \(authToken)",
        "Content-Type" : "application/json"]
    } else {
      headers = [
        "Authorization" : "",
        "Content-Type" : "application/json"]
    }

    var request = request
    for (headerKey, headerValue) in headers {
      request.setValue(headerValue, forHTTPHeaderField: headerKey)
    }
    return request
  }

  /// Performs a GET request using the specified URL
  /// - Parameters:
  ///   - reqURL: URL of the resource to GET.
  ///   - completion: Always called when the resource is either fetched from
  /// the network or from the cache.
  @objc func download(_ reqURL: URL,
                      completion: @escaping (_ result: Data?, _ response: URLResponse?,  _ error: Error?) -> Void) -> URLSessionDownloadTask {
    let req = request(for: reqURL)
    let completionWrapper: (_ result: NYPLResult<Data>) -> Void = { result in
      switch result {
      case let .success(data, response): completion(data, response, nil)
      case let .failure(error, response): completion(nil, response, error)
      }
    }

    let task = urlSession.downloadTask(with: req)
    responder.addCompletion(completionWrapper, taskID: task.taskIdentifier)
    task.resume()

    return task
  }

  /// Performs a GET request using the specified URL, if oauth token is available, it is added to the request
  /// - Parameters:
  ///   - reqURL: URL of the resource to GET.
  ///   - completion: Always called when the resource is either fetched from
  /// the network or from the cache.
  @objc func addBearerAndExecute(_ request: URLRequest,
                     completion: @escaping (_ result: Data?, _ response: URLResponse?,  _ error: Error?) -> Void) -> URLSessionDataTask {
    let req = NYPLNetworkExecutor.bearerAuthorized(request: request)
    let completionWrapper: (_ result: NYPLResult<Data>) -> Void = { result in
      switch result {
      case let .success(data, response): completion(data, response, nil)
      case let .failure(error, response): completion(nil, response, error)
      }
    }
    return executeRequest(req, completion: completionWrapper)
  }

  /// Performs a GET request using the specified URL
  /// - Parameters:
  ///   - reqURL: URL of the resource to GET.
  ///   - completion: Always called when the resource is either fetched from
  /// the network or from the cache.
  @objc func GET(_ reqURL: URL,
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

  /// Performs a PUT request using the specified URL
  /// - Parameters:
  ///   - reqURL: URL of the resource to PUT.
  ///   - completion: Always called when the resource is either fetched from
  /// the network or from the cache.
  @objc func PUT(_ reqURL: URL,
                 completion: @escaping (_ result: Data?, _ response: URLResponse?,  _ error: Error?) -> Void) -> URLSessionDataTask {
    var req = request(for: reqURL)
    req.httpMethod = "PUT"
    let completionWrapper: (_ result: NYPLResult<Data>) -> Void = { result in
      switch result {
      case let .success(data, response): completion(data, response, nil)
      case let .failure(error, response): completion(nil, response, error)
      }
    }
    return executeRequest(req, completion: completionWrapper)
  }
}
