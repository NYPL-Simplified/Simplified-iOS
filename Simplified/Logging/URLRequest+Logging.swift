//
//  URLRequest+NYPL.swift
//  SimplyE
//
//  Created by Ettore Pasquini on 4/8/20.
//  Copyright © 2020 NYPL. All rights reserved.
//

import Foundation

extension URLRequest {

  /// Since a request can include sensitive data such as access tokens, etc,
  /// this computed variable includes a "safe" set of data that we can log.
  var loggableString: String {
    let methodAndURL = "\(httpMethod ?? "") \(url?.absoluteString ?? "")"
    let headers = allHTTPHeaderFields?.filter {
      $0.key.lowercased() != "authorization"
    } ?? [:]

    return "\(methodAndURL)\n  headers: \(headers)"
  }
}

@objc extension NSURLRequest {
  var loggableString: String {
    return (self as URLRequest).loggableString
  }
}
