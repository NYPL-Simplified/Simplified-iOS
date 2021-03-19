//
//  Date+NYPLAdditions.swift
//  SimplyE
//
//  Created by Ettore Pasquini on 3/25/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

public extension Date {

  /// A static date formatter to get date strings formatted per RFC 1123
  /// without incurring in the high cost of creating a new DateFormatter
  /// each time, which would be ~300% more expensive.
  static let rfc1123DateFormatter: DateFormatter = {
    let df = DateFormatter()
    df.locale = Locale(identifier: "en_US")
    df.timeZone = TimeZone(identifier: "GMT")
    df.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
    return df
  }()

  /// A date string formatted per RFC 1123 for insertion into a HTTP
  /// header field (such as the `Expires` header in a HTTP response).
  /// Example: Wed, 25 Mar 2020 01:23:45 GMT
  var rfc1123String: String {
    return Date.rfc1123DateFormatter.string(from: self)
  }
}
