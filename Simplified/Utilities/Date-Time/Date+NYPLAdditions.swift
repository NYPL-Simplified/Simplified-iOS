//
//  Date+NYPLAdditions.swift
//  SimplyE
//
//  Created by Ettore Pasquini on 3/25/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

enum NYPLDateType {
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
      return "\(Int(years)) " + dateSuffix(dateType: .year, suffixType: suffixType, isPlural: true)
    } else if(months >= 4) {
      // Switch to months after ~16 weeks.
      return "\(Int(months)) " + dateSuffix(dateType: .month, suffixType: suffixType, isPlural: true)
    } else if(weeks >= 4) {
      // Switch to weeks after 28 days.
      return "\(Int(weeks)) " + dateSuffix(dateType: .week, suffixType: suffixType, isPlural: true)
    } else if(days >= 2) {
      // Switch to days after 48 hours.
      return "\(Int(days)) " + dateSuffix(dateType: .day, suffixType: suffixType, isPlural: true)
    } else {
      // Use hours.
      return "\(Int(hours)) " + dateSuffix(dateType: .hour, suffixType: suffixType, isPlural: hours != 1)
    }
  }
  
  private func dateSuffix(dateType: NYPLDateType, suffixType: NYPLDateSuffixType, isPlural: Bool) -> String {
    if suffixType == .short {
      switch dateType {
      case .year:
        return NSLocalizedString("year_suffix_short", comment: "Year (Date Suffix)")
      case .month:
        return NSLocalizedString("month_suffix_short", comment: "Month (Date Suffix)")
      case .week:
        return NSLocalizedString("week_suffix_short", comment: "Week (Date Suffix)")
      case .day:
        return NSLocalizedString("day_suffix_short", comment: "Day (Date Suffix)")
      default:
        return NSLocalizedString("hour_suffix_short", comment: "Hour (Date Suffix)")
      }
    }
    
    switch dateType {
    case .year:
      return NSLocalizedString(isPlural ? "year_suffix_plural" : "year_suffix_long", comment: "Year (Date Suffix)")
    case .month:
      return NSLocalizedString(isPlural ? "month_suffix_plural" : "month_suffix_long", comment: "Month (Date Suffix)")
    case .week:
      return NSLocalizedString(isPlural ? "week_suffix_plural" : "week_suffix_long", comment: "Week (Date Suffix)")
    case .day:
      return NSLocalizedString(isPlural ? "day_suffix_plural" : "day_suffix_long", comment: "Day (Date Suffix)")
    default:
      return NSLocalizedString(isPlural ? "hour_suffix_plural" : "hour_suffix_long", comment: "Hour (Date Suffix)")
    }
  }
}
