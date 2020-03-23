//
//  NYPLCaching.swift
//  SimplyE
//
//  Created by Ettore Pasquini on 3/19/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

//------------------------------------------------------------------------------
extension HTTPURLResponse {
  var hasCorrectCachingHeaders: Bool {
    return cacheControlHeader != nil && expiresHeader != nil
  }

  var cacheControlMaxAge: TimeInterval? {
    guard let cacheControl = cacheControlHeader else {
      return nil
    }

    let directives = cacheControl.split(separator: ",")
    let maxAgeDirectives = directives.filter {
      $0.trimmingCharacters(in: .whitespacesAndNewlines)
        .lowercased()
        .starts(with: "max-age")
    }
    guard let maxAgeDirective = maxAgeDirectives.first else {
      return nil
    }

    var separator = Character("=")
    if maxAgeDirective.contains(":") {
      separator = Character(":")
    }
    var maxAgeKeyAndValue = maxAgeDirective.split(separator: separator)
    // since we're splitting a key-value pair (e.g. "maxAge=123") we'll need
    // at least 2 elements in the split array
    guard maxAgeKeyAndValue.count >= 2 else {
      return nil
    }

    maxAgeKeyAndValue.removeFirst() // discard key
    let maxAgeStr = maxAgeKeyAndValue.first?
      .trimmingCharacters(in: .whitespacesAndNewlines)

    if let maxAgeStr = maxAgeStr, let maxAgeVal = TimeInterval(maxAgeStr) {
      return maxAgeVal
    }

    return nil
  }

  var cacheControlHeader: String? {
    let responseHeaders = self.allHeaderFields

    if let cacheControl = responseHeaders["Cache-Control"] as? String {
      return cacheControl
    }

    if let cacheControl = responseHeaders["CACHE-CONTROL"] as? String {
      return cacheControl
    }

    if let cacheControl = responseHeaders["cache-control"] as? String {
      return cacheControl
    }

    return nil
  }

  var expiresHeader: String? {
    let responseHeaders = self.allHeaderFields

    if let expires = responseHeaders["Expires"] as? String {
      return expires
    }

    if let expires = responseHeaders["EXPIRES"] as? String {
      return expires
    }

    if let expires = responseHeaders["expires"] as? String {
      return expires
    }

    return nil
  }

  func modifyingCacheHeaders(for req: URLRequest) -> HTTPURLResponse {
    // convert existing headers into a [String: String] dictionary we can use
    // later
    let headerPairs: [(String, String)] = self.allHeaderFields.compactMap {
      if let key = $0.key as? String, let val = $0.value as? String {
        return (key, val)
      }
      return nil
    }
    var headers = [String: String](uniqueKeysWithValues: headerPairs)

    // add manual 3 hours caching if needed
    if self.expiresHeader == nil {
      let maxAge: TimeInterval = {
        if let age = self.cacheControlMaxAge {
          return age
        }
        return 60 * 60 * 3
      }()
      let in3HoursDate = NSDate().addingTimeInterval(maxAge)
      headers["Expires"] = in3HoursDate.rfc1123String()
    }
    if self.cacheControlHeader == nil {
      headers["Cache-Control"] = "public, max-age=10800"
    }

    // new response with added caching
    guard
      let url = req.url,
      let newResponse = HTTPURLResponse(
        url: url,
        statusCode: statusCode,
        httpVersion: nil,
        headerFields: headers) else {
          Log.error(#file, """
            Unable to create HTTPURLResponse with added cache-control headers \
            for url \(req). Original response: \(self)
            """)
          return self
    }

    return newResponse
  }
}

//------------------------------------------------------------------------------
extension URLCache {
  func replaceCachedResponse(_ response: HTTPURLResponse,
                             data: Data,
                             for req: URLRequest) {
    let newResponse = response.modifyingCacheHeaders(for: req)
    self.removeCachedResponse(for: req)
    let cachedResponse = CachedURLResponse(response: newResponse, data: data)
    self.storeCachedResponse(cachedResponse, for: req)
  }
}

//------------------------------------------------------------------------------
class NYPLCaching {

  /// Makes a URLSessionConfiguration for standard HTTP requests with in-memory
  /// and disk caching enabled if the server sends appropriate cache-control
  /// headers.
  class func makeURLSessionConfiguration() -> URLSessionConfiguration {
    let config = URLSessionConfiguration.default
    config.networkServiceType = .responsiveData
    config.shouldUseExtendedBackgroundIdleMode = true
    config.httpMaximumConnectionsPerHost = 8
    config.httpShouldUsePipelining = true

    config.requestCachePolicy = .useProtocolCachePolicy
    config.urlCache = makeCache()

    if #available(iOS 11.0, *) {
      Log.debug(#file, "waitsForConnectivity: \(config.waitsForConnectivity)")
      //config.waitsForConnectivity = true
    }

    if #available(iOS 13.0, *) {
      Log.debug(#file, "allowsExpensiveNetworkAccess: \(config.allowsExpensiveNetworkAccess)")
      Log.debug(#file, "allowsConstrainedNetworkAccess: \(config.allowsConstrainedNetworkAccess)")

      // we probably want this set to true because SimplyE might be used
      // with personal hotspots
      config.allowsExpensiveNetworkAccess = true

      // enabling this otherwise network operations fail in Low Data mode
      config.allowsConstrainedNetworkAccess = true
    }

    return config
  }

  // note: iPhone 4S (currently the smallest device we support on iOS 9.3) has
  // 512 MB RAM and 8 Gb disk. These sizes are automatically purged by the
  // system if needed.
  private static let maxMemoryCapacity = 50 * 1024 * 1024 // 50 MB
  private static let maxDiskCapacity = 1024 * 1024 * 1024 // 1 GB

  private class func makeCache() -> URLCache {
    if #available(iOS 13.0, *) {
      let cache = URLCache(memoryCapacity: maxMemoryCapacity,
                           diskCapacity: maxDiskCapacity,
                           directory: nil)
      return cache
    } else {
      let cache = URLCache(memoryCapacity: maxMemoryCapacity,
                           diskCapacity: maxDiskCapacity,
                           diskPath: nil)
      return cache
    }
  }
}
