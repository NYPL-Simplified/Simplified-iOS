//
//  NYPLUserFriendlyError.swift
//  Simplified
//
//  Created by Ettore Pasquini on 7/15/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

/// A protocol describing an error that MAY offer user friendly
/// messaging to the user.
protocol NYPLUserFriendlyError: Error {
  /// A short summary of the error, if available.
  var userFriendlyTitle: String? { get }

  /// A user-friendly short message describing the error in more detail,
  /// if possible.
  var userFriendlyMessage: String? { get }
}

// Dummy implementation merely to ease error reporting work upstream, where
// it's very common to have to handle errors obtained in various ways. This
// is also ok because user friendly strings are in general never guaranteed
// to be there, even when we obtain a problem document.
extension NYPLUserFriendlyError {
  var userFriendlyTitle: String? { return nil }
  var userFriendlyMessage: String? { return nil  }
}

extension NSError: NYPLUserFriendlyError {
  private static let userFriendlyTitleKey = "userFriendlyTitle"
  private static let userFriendlyMessageKey = "userFriendlyMessage"

  var userFriendlyTitle: String? {
    return userInfo[NSError.userFriendlyTitleKey] as? String
  }

  var userFriendlyMessage: String? {
    return (userInfo[NSError.userFriendlyMessageKey] ?? userInfo[NSLocalizedDescriptionKey]) as? String
  }

  /// Builds an NSError using the given problem document for its user-friendly
  /// messaging.
  /// - Parameters:
  ///   - problemDoc: The problem document per RFC7807.
  ///   - domain: The domain to give to the error being created.
  ///   - code: The code to give to the error being created.
  ///   - userInfo: The user friendly messaging will be appended to this
  ///   dictionary.
  /// - Returns: A new NSError with the ProblemDocument `title` and `detail`.
  static func makeFromProblemDocument(_ problemDoc: NYPLProblemDocument,
                                      domain: String,
                                      code: Int,
                                      userInfo: [String: Any]?) -> NSError {
    var userInfo = userInfo ?? [String: Any]()
    if let title = problemDoc.title {
      userInfo[NSError.userFriendlyTitleKey] = title
    }
    if let detail = problemDoc.detail {
      userInfo[NSError.userFriendlyMessageKey] = detail
    }
    
    return NSError(domain: domain, code: code, userInfo: userInfo)
  }
}
