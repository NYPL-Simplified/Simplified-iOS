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

class NYPLNetworkExecutor {
  private let urlSession: URLSession

  init() {
    let config = NYPLCaching.makeURLSessionConfiguration()
    self.urlSession = URLSession(configuration: config)
  }

  deinit {
    urlSession.invalidateAndCancel()
  }

  /// Singleton interface
  /// - Note: There's no real reason why this should be a singleton. One
  /// could create multiple executors as needed with no problems. However,
  /// this shared object can be used as a quick interface to centralize
  /// network traffic,
  static let shared = NYPLNetworkExecutor()

  /// By setting this to `true`, one can enable caching even if the response is
  /// missing the required caching headers. This works by modifying the headers
  /// of the cached response in order to enforce a 3 hour caching window.
  var shouldEnableFallbackCaching: Bool = true

  func executeRequest(_ reqURL: URL,
                      completion: @escaping (_ result: NYPLResult<Data>) -> Void) {

    let req = request(for: reqURL)

    let startDate = Date()
    let task = urlSession.dataTask(with: req) { data, response, error in
      let endDate = Date()
      Log.info(#file, """
        Request \(String(describing: req.httpMethod)) \(req) took \
        \(endDate.timeIntervalSince(startDate)) secs
        """)

      if let error = error {
        let err = NYPLErrorLogger.logNetworkError(error,
                                                  requestURL: reqURL,
                                                  response: response)
        completion(.failure(err))
        return
      }

      guard let httpResponse = response as? HTTPURLResponse else {
        let err = NYPLErrorLogger.logNetworkError(requestURL: reqURL,
                                                  response: response,
                                                  message: "Not a HTTPURLResponse")
        completion(.failure(err))
        return
      }
      Log.debug(#file, "Response for \(req): \(httpResponse)")

      guard let data = data else {
        let err = NYPLErrorLogger.logNetworkError(requestURL: reqURL,
                                                  response: response,
                                                  message: "No data received")
        completion(.failure(err))
        return
      }

      if self.shouldEnableFallbackCaching {
        if !httpResponse.hasSufficientCachingHeaders {
          self.urlSession.configuration.urlCache?
            .replaceCachedResponse(httpResponse, data: data, for: req)
        }
      }

      completion(.success(data))
    }

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
