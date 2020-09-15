//
//  AudioBookVendorsHelper.swift
//  Simplified
//
//  Created by Vladimir Fedorov on 10.09.2020.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation


/// This is a helper class to use with Objective-C code
@objc public class AudioBookVendorsHelper: NSObject {
  
  /// Get vendor for the book JSON data
  /// - Parameter book: Book JSON dictionary
  /// - Returns: AudioBookVendors vendor item, if found, `nil` otherwise
  private static func feedbookVendor(for book: [String: Any]) -> AudioBookVendors? {
    guard let metadata = book["metadata"] as? [String: Any],
      let signature = metadata["http://www.feedbooks.com/audiobooks/signature"] as? [String: Any],
      let issuer = signature["issuer"] as? String
      else {
        return nil
    }
    switch issuer {
    case "https://www.cantookaudio.com": return .cantook
    default: return nil
    }
  }
  
  /// Check if vendor key is valid and update it if not.
  /// - Parameters:
  ///   - book: Book JSON dictionary
  ///   - completion: completion
  @objc public static func updateVendorKey(book: [String: Any], completion: @escaping (_ error: NSError?) -> ()) {
    if let vendor = self.feedbookVendor(for: book) {
      vendor.updateDrmCertificate { error in
        completion(self.nsError(for: error))
      }
    } else {
      completion(nil)
    }
  }
  
  /// Creates an NSError for Objective-C code providing a readable error message for `DPLAError` errors
  /// - Parameter error: Error object
  /// - Returns: NSError object
  private static func nsError(for error: Error?) -> NSError? {
    guard let error = error else {
      return nil
    }
    let domain = "SimplyE.AudioBookVendorsHelper"
    let code = 0
    var description = error.localizedDescription
    if let dplaError = error as? DPLAAudiobooks.DPLAError {
      description = dplaError.readableError
    }
    return NSError(domain: domain, code: code, userInfo: [
      NSLocalizedDescriptionKey: description
    ])
  }
}
