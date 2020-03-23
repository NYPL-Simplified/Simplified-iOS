//
//  NYPLNetworkExecutor.swift
//  SimplyE
//
//  Created by Ettore Pasquini on 3/19/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

enum NYPLResult<SuccessInfo> {
  case success(SuccessInfo)
  case failure(Error)
}


/// A class that is capable of executing network requests in a thread-safe way.
/// This class implements caching according to server response caching headers,
/// but can also be configured to have a fallback mechanism to cache responses
/// that lack a sufficient set of caching headers. This fallback cache attempts
/// to use the value found in the `max-age` directive of the `Cache-Control`
/// header if present, otherwise defaults to 3 hours.
///
/// The cache lives on both memory and disk.
class NYPLNetworkExecutor {
  private let urlSession: URLSession

  /// The delegate of the URLSession.
  private let responder: NYPLNetworkResponder

  /// Whether the fallback caching system should be active or not.
  let shouldEnableFallbackCaching: Bool

  /// Designated initializer.
  /// - Parameter shouldEnableFallbackCaching: If set to `true`, the executor
  /// will attempt to cache responses even when these lack a sufficient set of
  /// caching headers. The default is `false`.
  init(shouldEnableFallbackCaching: Bool = false) {
    self.shouldEnableFallbackCaching = shouldEnableFallbackCaching
    self.responder = NYPLNetworkResponder()
    let config = NYPLCaching.makeURLSessionConfiguration()
    self.urlSession = URLSession(configuration: config,
                                 delegate: self.responder,
                                 delegateQueue: nil)
  }

  deinit {
    urlSession.invalidateAndCancel()
  }

  /// A shared generic executor with enabled fallback caching.
  static let shared = NYPLNetworkExecutor(shouldEnableFallbackCaching: true)

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

  /// Executes a given request.
  /// - Parameters:
  ///   - req: The request to perform.
  ///   - completion: Always called when the resource is either fetched from
  /// the network or from the cache.
  func executeRequest(_ req: URLRequest,
           completion: @escaping (_ result: NYPLResult<Data>) -> Void) {
    let task = urlSession.dataTask(with: req)
    responder.addCompletion(completion, taskID: task.taskIdentifier)
    task.resume()
  }
}

extension NYPLNetworkExecutor {
  private func request(for url: URL) -> URLRequest {
    return URLRequest(url: url,
                      cachePolicy: urlSession.configuration.requestCachePolicy)
  }

  func clearCache() {
    urlSession.configuration.urlCache?.removeAllCachedResponses()
  }
}
