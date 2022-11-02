//
//  Date+NYPLAdditions.swift
//  SimplyE
//
//  Created by Ettore Pasquini on 3/25/20.
//  Copyright © 2020 NYPL. All rights reserved.
//

import Foundation

enum NYPLDateType: String {
  case year
  case month
  case week
  case day
  case hour
}

public enum NYPLDateSuffixType {
  case long
  case short
}

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

  /// A date string with the choice of short or long suffix
  /// Example: 5 years / 5 y / 6 months / 1 day
  func timeUntilString(suffixType: NYPLDateSuffixType) -> String {
    var seconds = self.timeIntervalSince(Date())
    seconds = max(seconds, 0)
    let minutes = floor(seconds / 60)
    let hours = floor(minutes / 60)
    let days = floor(hours / 24)
    let weeks = floor(days / 7)
    let months = floor(days / 30)
    let years = floor(days / 365)
    
    if(years >= 4) {
      // Switch to years after ~48 months.
      return String.localizedStringWithFormat(dateSuffix(dateType: .year, suffixType: suffixType, isPlural: true), Int(years))
    } else if(months >= 4) {
      // Switch to months after ~16 weeks.
      return String.localizedStringWithFormat(dateSuffix(dateType: .month, suffixType: suffixType, isPlural: true), Int(months))
    } else if(weeks >= 4) {
      // Switch to weeks after 28 days.
      return String.localizedStringWithFormat(dateSuffix(dateType: .week, suffixType: suffixType, isPlural: true), Int(weeks))
    } else if(days >= 2) {
      // Switch to days after 48 hours.
      return String.localizedStringWithFormat(dateSuffix(dateType: .day, suffixType: suffixType, isPlural: true), Int(days))
    } else {
      // Use hours.
      return String.localizedStringWithFormat(dateSuffix(dateType: .hour, suffixType: suffixType, isPlural: hours != 1), Int(hours))
    }
  }
  
  private func dateSuffix(dateType: NYPLDateType, suffixType: NYPLDateSuffixType, isPlural: Bool) -> String {
    if suffixType == .short {
      return NSLocalizedString("\(dateType.rawValue)_suffix_short", comment: "Date Suffix (Short)")
    }
    return NSLocalizedString("\(dateType.rawValue)_suffix_long", comment: "Date Suffix (Long)")
  }
}

@objc extension NSDate {
  func longTimeUntilString() -> String {
    return (self as Date).timeUntilString(suffixType: .long)
  }
}
