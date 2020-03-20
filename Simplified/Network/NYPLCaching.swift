//
//  NYPLCaching.swift
//  SimplyE
//
//  Created by Ettore Pasquini on 3/19/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

extension HTTPURLResponse {
  var hasCorrectCacheControlHeaders: Bool {
    let responseHeaders = self.allHeaderFields
    return responseHeaders["Cache-Control"] != nil
      || responseHeaders["cache-control"] != nil
      || responseHeaders["CACHE-CONTROL"] != nil
  }
}

class NYPLCaching {

  /// Makes a URLSEssionCongiguration for standard HTTP requests with in-memory
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
