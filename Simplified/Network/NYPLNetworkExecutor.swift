//
//  NYPLNetworkExecutor.swift
//  SimplyE
//
//  Created by Ettore Pasquini on 3/19/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

enum Result<Success> {
  case success(Success)
  case failure(Error)
}

class NYPLNetworkExecutor: NSObject {
  var urlSession: URLSession

  override init() {
    let config = NYPLCaching.makeURLSessionConfiguration()
    self.urlSession = URLSession(configuration: config)
    super.init()
  }

  /// Singleton interface
  /// - Note: There's no real reason why this should be a singleton. In theory
  /// one could create multiple executors as needed, but as a quick interface
  /// to centralize network traffic, this shared object could be used.
  static let shared = NYPLNetworkExecutor()

  func executeRequest(_ reqURL: URL,
                      completion: @escaping (_ result: Result<Data>) -> Void) {

    let req = request(for: reqURL)

    let task = urlSession.dataTask(with: req) { data, response, error in
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

      guard httpResponse.statusCode == 200 else {
        let err = NYPLErrorLogger.logNetworkError(requestURL: reqURL,
                                                  response: httpResponse,
                                                  message: "Response code != 200")
        completion(.failure(err))
        return
      }

      guard let data = data else {
        let err = NYPLErrorLogger.logNetworkError(requestURL: reqURL,
                                                  response: response,
                                                  message: "No data received")
        completion(.failure(err))
        return
      }

      if !httpResponse.hasCorrectCachingHeaders {
        self.urlSession.configuration.urlCache?
          .replaceCachedResponse(httpResponse, data: data, for: req)
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
