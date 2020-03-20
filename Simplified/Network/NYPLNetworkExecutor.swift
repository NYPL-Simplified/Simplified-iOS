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

struct NYPLServerData {
  let data: Data
  let responseHasCorrectCacheControlHeaders: Bool

  init(data: Data, httpResponse: HTTPURLResponse) {
    self.data = data
    self.responseHasCorrectCacheControlHeaders = httpResponse.hasCorrectCacheControlHeaders
  }
}

enum NYPLCachedControl {
  case correct
  case incorrect
  case notCached
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

  private func request(for url: URL) -> URLRequest {
    return URLRequest(url: url,
                      cachePolicy: urlSession.configuration.requestCachePolicy)
  }

  func executeRequest(_ reqURL: URL,
                      completion: @escaping (_ result: Result<NYPLServerData>) -> Void) {

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

      if !httpResponse.hasCorrectCacheControlHeaders {
        self.manuallyCache(data, response: httpResponse, for: req)
      }

      completion(.success(NYPLServerData(data: data,
                                         httpResponse: httpResponse)))
    }

    task.resume()
  }

  func manuallyCache(_ data: Data, response: HTTPURLResponse, for req: URLRequest) {
    // convert existing headers into a [String: String] dictionary we can use
    // later
    let headerPairs: [(String, String)] = response.allHeaderFields.compactMap {
      if let key = $0.key as? String, let val = $0.value as? String {
        return (key, val)
      }
      return nil
    }
    var headers = [String: String](uniqueKeysWithValues: headerPairs)

    // add manual 3 hours caching. Note
    headers["Cache-Control"] = "public, max-age: 10800"
    let in3HoursData = NSDate().addingTimeInterval(60 * 60 * 3)
    headers["Expires"] = in3HoursData.rfc1123String()

    // new response with added caching
    guard
      let url = req.url,
      let newResponse = HTTPURLResponse(
        url: url,
        statusCode: response.statusCode,
        httpVersion: nil,
        headerFields: headers) else {
          Log.error(#file, """
            Unable to create HTTPURLResponse with added cache-control headers \
            for url \(req). Original response: \(response)
            """)
          return
    }

    let cachedResponse = CachedURLResponse(response: newResponse, data: data)
    let cache = urlSession.configuration.urlCache
    cache?.removeCachedResponse(for: req)
    cache?.storeCachedResponse(cachedResponse, for: req)
  }

  func cacheControlForResource(at url: URL) -> NYPLCachedControl {
    let req = request(for: url)
    let cached = urlSession.configuration.urlCache?.cachedResponse(for: req)

    guard let httpResponse = cached?.response as? HTTPURLResponse else {
      return .notCached
    }

    if httpResponse.hasCorrectCacheControlHeaders {
      return .correct
    } else {
      return .incorrect
    }
  }

  func clearCache() {
    urlSession.configuration.urlCache?.removeAllCachedResponses()
  }
}
