//
//  NYPLRequestExecuting.swift
//  Simplified
//
//  Created by Ettore Pasquini on 3/24/21.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

let NYPLDefaultRequestTimeout: TimeInterval = 30.0

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

