//
//  NYPLRequestExecuting.swift
//  Simplified
//
//  Created by Ettore Pasquini on 3/24/21.
//  Copyright © 2021 NYPL. All rights reserved.
//

import Foundation
import NYPLUtilities

let NYPLDefaultRequestTimeout: TimeInterval = 65.0

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

  static var defaultRequestTimeout: TimeInterval {get}
}

extension NYPLRequestExecuting {
  var requestTimeout: TimeInterval {
    return Self.defaultRequestTimeout
  }

  static var defaultRequestTimeout: TimeInterval {
    return NYPLDefaultRequestTimeout
  }
}

protocol NYPLHTTPRequestExecuting: NYPLRequestExecuting {
  func GET(_ reqURL: URL,
           cachePolicy: URLRequest.CachePolicy?,
           completion: @escaping (_ result: NYPLResult<Data>) -> Void)

  func POST(_ reqURL: URL,
            additionalHeaders: [String: String]?,
            httpBody: Data?,
            completion: @escaping (_ result: NYPLResult<Data>) -> Void)

  func DELETE(_ reqURL: URL,
              completion: @escaping (_ result: NYPLResult<Data>) -> Void)
}

/// Protocol for Objective-C compatibility.
@objc protocol NYPLHTTPRequestExecutingBasic {
  func GET(_ reqURL: URL,
           cachePolicy: NSURLRequest.CachePolicy,
           completion: @escaping (_ result: Data?,
                                  _ response: URLResponse?,
                                  _ error: Error?) -> Void) -> URLSessionDataTask
}

protocol NYPLOAuthTokenFetching {
  func fetchAndStoreShortLivedOAuthToken(
    at url: URL,
    completion: @escaping (_ result: NYPLResult<NYPLOAuthAccessToken>) -> Void)

  func resetLibrarySpecificInfo()
}
