//
//  AudiobookCertificate.swift
//  Simplified
//
//  Created by Vladimir Fedorov on 10.09.2020.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation


/// This is a helper class to use with Objective-C code
/// Swift `enum`s are not accessible in Objective-C code
@objc public class AudiobookCertificate: NSObject {
  
  /// Get vendor for the book JSON data
  /// - Parameter book: Book JSON dictionary
  /// - Returns: AudioBookVendors vendor item, if found, `nil` otherwise
  static func feedbookVendor(for book: [String: Any]) -> AudioBookVendors? {
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
  @objc public static func updateVendorKey(book: [String: Any], completion: @escaping (_ error: Error?) -> ()) {
    if let vendor = self.feedbookVendor(for: book) {
      vendor.updateDrmCertificate { error in
        completion(error)
      }
    } else {
      completion(nil)
    }
  }
}
