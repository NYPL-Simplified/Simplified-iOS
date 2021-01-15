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
  /**
   It appears that a `Cache-Control` header alone is not sufficient for having
   URLSession cache the response AND use that cached response without incurring
   in a second roundtrip, even if `max-age`/`s-maxage` is included. When using
   the `Cache-Control` header, empirical observations suggest that either the
   `Expires` OR `Last-Modified` header needs to be present as well.

   Alternatively (i.e. without using `Cache-Control`), `Expires` can be used
   in conjuction with `Last-Modified` or `ETag`, or the latter two can be used
   together.

   - Note: If `Cache-Control` contains a `must-revalidate` directive, URLSession
   will always perform a GET roundtrip to validate the cache. This computed
   property does not check for its presence since in that case the server
   explicitly demands a revalidation.
   */
  var hasSufficientCachingHeaders: Bool {
    if cacheControlHeader != nil {
      if lastModifiedHeader != nil || expiresHeader != nil {
        return true
      }
    }

    if expiresHeader != nil {
      if  lastModifiedHeader != nil || eTagHeader != nil {
        return true
      }
    }

    if lastModifiedHeader != nil && eTagHeader != nil {
      return true
    }

    return false
  }

  /**
   Extracts the value of the `max-age` directive from the `Cache-Control` header.
   */
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
    return header(named: "Cache-Control")
  }

  var expiresHeader: String? {
    return header(named: "Expires")
  }

  var lastModifiedHeader: String? {
    return header(named: "Last-Modified")
  }

  var eTagHeader: String? {
    return header(named: "ETag")
  }

  /// Checks capitalization of given header key, including capitalized,
  /// lowercase and uppercase variations.
  /// - Parameter header: The name of a header to check.
  private func header(named header: String) -> String? {
    let responseHeaders = self.allHeaderFields

    if let value = responseHeaders[header] as? String {
      return value
    }

    if let value = responseHeaders[header.capitalized] as? String {
      return value
    }

    if let value = responseHeaders[header.uppercased()] as? String {
      return value
    }

    if let value = responseHeaders[header.lowercased()] as? String {
      return value
    }

    return nil
  }

  /// Creates a new response by adding caching headers sufficient to avoid
  /// a roundtrip. The caching headers being added are `Cache-Control` and
  /// `Expires` and they are only added if they were missing from the original
  /// response (i.e. `self`). The added caching window is either `max-age` if
  /// that directive is present in `Cache-Control`, otherwise it's 3 hours.
  func modifyingCacheHeaders() -> HTTPURLResponse {
    // don't mess with failed responses
    guard statusCode >= 200 && statusCode <= 299 else {
      return self
    }

    // convert existing headers into a [String: String] dictionary we can use
    // later
    let headerPairs: [(String, String)] = self.allHeaderFields.compactMap {
      if let key = $0.key as? String, let val = $0.value as? String {
        return (key, val)
      }
      return nil
    }
    var headers = [String: String](uniqueKeysWithValues: headerPairs)

    // use `max-age` value if present, otherwise use 3 hours for both
    // `max-age` and `Expires`.
    if self.expiresHeader == nil {
      let maxAge: TimeInterval = {
        if let age = self.cacheControlMaxAge {
          return age
        }
        return 60 * 60 * 3
      }()
      let in3HoursDate = Date().addingTimeInterval(maxAge)
      headers["Expires"] = in3HoursDate.rfc1123String
    }
    if self.cacheControlHeader == nil {
      headers["Cache-Control"] = "public, max-age=10800"
    }

    // new response with added caching
    guard
      let url = self.url,
      let newResponse = HTTPURLResponse(
        url: url,
        statusCode: statusCode,
        httpVersion: nil,
        headerFields: headers) else {
          Log.error(#file, """
            Unable to create new HTTPURLResponse with added cache-control \
            headers from original response: \(self)
            """)
          return self
    }

    return newResponse
  }
}

//------------------------------------------------------------------------------
class NYPLCaching {

  /// Makes a URLSessionConfiguration for standard HTTP requests with in-memory
  /// and disk caching enabled.
  class func makeURLSessionConfiguration() -> URLSessionConfiguration {
    let config = URLSessionConfiguration.default
    config.networkServiceType = .responsiveData
    config.shouldUseExtendedBackgroundIdleMode = true
    config.httpMaximumConnectionsPerHost = 8
    config.httpShouldUsePipelining = true
    config.timeoutIntervalForRequest = 30
    config.timeoutIntervalForResource = 60
    config.requestCachePolicy = .useProtocolCachePolicy
    config.urlCache = makeCache()

    if #available(iOS 11.0, *) {
      config.waitsForConnectivity = true
    }

    if #available(iOS 13.0, *) {
      // we probably want this set to true because SimplyE might be used
      // with personal hotspots
      config.allowsExpensiveNetworkAccess = true

      // enabling this otherwise network operations fail in Low Data mode
      config.allowsConstrainedNetworkAccess = true
    }

    return config
  }

  // Note: iPhone 4S (currently the smallest device we support on iOS 9.3) has
  // 512 MB RAM and 8 Gb disk. These sizes are automatically purged by the
  // system if needed.
  private static let maxMemoryCapacity = 20 * 1024 * 1024 // 20 MB
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
