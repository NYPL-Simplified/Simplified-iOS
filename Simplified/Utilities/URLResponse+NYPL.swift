//
//  URLResponse+NYPL.swift
//  SimplyE
//
//  Created by Ettore Pasquini on 7/9/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

extension URLResponse {

  /// Determines if the response is a Problem Document response per
  /// https://tools.ietf.org/html/rfc7807.
  /// - Returns: `true` is the response contains a problem Document,
  /// `false` otherwise.
  @objc func isProblemDocument() -> Bool {
    guard let mimeType = mimeType else {
      return false
    }

    return mimeType == "application/problem+json" ||
      mimeType == "application/api-problem+json"
  }
}

extension HTTPURLResponse {
  @objc func isSuccess() -> Bool {
    return statusCode >= 200 && statusCode <= 299
  }
}
