//
//  NYPLUserFriendlyError.swift
//  Simplified
//
//  Created by Ettore Pasquini on 7/15/20.
//  Copyright © 2020 NYPL. All rights reserved.
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

  /// The status code of a HTTP response, if present. Should be 0 otherwise.
  var httpStatusCode: Int { get }

  /// The problem document from the server, if available.
  var problemDocument: NYPLProblemDocument? { get }
}

// Dummy implementation merely to ease error reporting work upstream, where
// it's very common to have to handle errors obtained in various ways. This
// is also ok because user friendly strings are in general never guaranteed
// to be there, even when we obtain a problem document.
extension NYPLUserFriendlyError {
  var userFriendlyTitle: String? { return nil }
  var userFriendlyMessage: String? { return nil  }
  var httpStatusCode: Int { return 0 }
  var problemDocument: NYPLProblemDocument? { return nil }
}

extension NSError: NYPLUserFriendlyError {
  private static let problemDocumentKey = "problemDocument"
  public static let httpResponseKey = "response"
  public static let httpResponseContentKey = "responseContent"

  @objc var problemDocument: NYPLProblemDocument? {
    return userInfo[NSError.problemDocumentKey] as? NYPLProblemDocument
  }

  var httpResponse: HTTPURLResponse? {
    return userInfo[NSError.httpResponseKey] as? HTTPURLResponse
  }

  /// Feeds off of the `problemDocument` computed property
  @objc var userFriendlyTitle: String? {
    return problemDocument?.title
  }

  /// Feeds off of the `problemDocument` computed property or the localized
  /// error description.
  @objc var userFriendlyMessage: String? {
    return (problemDocument?.detail ?? userInfo[NSLocalizedDescriptionKey]) as? String
  }

  @objc var httpStatusCode: Int {
    return httpResponse?.statusCode ?? 0
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
    userInfo[NSError.problemDocumentKey] = problemDoc
    return NSError(domain: domain, code: code, userInfo: userInfo)
  }

  static func makeGenericServerErrorMessage(forHTTPStatus code: Int) -> String {
    return NSLocalizedString("Server response failure", comment: "")
    + " (" + String(code) + "). "
    + NSLocalizedString("Please check your connection or try again later.",
                        comment: "Generic recovery message")
  }
}
