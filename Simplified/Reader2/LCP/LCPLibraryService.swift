//
//  LCPLibraryService.swift
//
//  Created by Mickaël Menu on 01.02.19.
//
//  Copyright 2019 Readium Foundation. All rights reserved.
//  Use of this source code is governed by a BSD-style license which is detailed
//  in the LICENSE file present in the project repository where this source code is maintained.
//

#if LCP

import Foundation
import UIKit
import R2Shared
import ReadiumLCP


@objc class LCPLibraryService: NSObject, DRMLibraryService {
  
  /// Readium licensee file extension
  @objc public let licenseExtension = "lcpl"
  
  /// Readium LCPService
  private var lcpService = LCPService()
  
  /// ContentProtection unlocks protected publication, providing a custom `Fetcher`
  lazy var contentProtection: ContentProtection? = lcpService.contentProtection()
  
  /// [LicenseDocument.id: passphrase callback]
  private var authenticationCallbacks: [String: (String?) -> Void] = [:]
  
  /// Returns whether this DRM can fulfill the given file into a protected publication.
  /// - Parameter file: file URL
  /// - Returns: `true` if file contains LCP DRM license information.
  func canFulfill(_ file: URL) -> Bool {
    return file.pathExtension.lowercased() == licenseExtension
  }
  
  /// Fulfill LCP license publication.
  /// - Parameter file: LCP license file.
  /// - Returns: fulfilled publication as `Deferred` (`CancellableReesult` interenally) object.
  func fulfill(_ file: URL) -> Deferred<DRMFulfilledPublication, Error> {
    return deferred { completion in
      self.lcpService.acquirePublication(from: file) { result in
        completion(result
          .map {
            DRMFulfilledPublication(
              localURL: $0.localURL,
              suggestedFilename: $0.suggestedFilename
            )
        }
        .eraseToAnyError()
        )
      }
    }
  }

  /// Fulfill LCP license publication
  /// This function was added for compatibility with Objective-C NYPLMyBooksDownloadCenter.
  /// - Parameters:
  ///   - file: LCP license file.
  ///   - completion: Completion is called after a publication was downloaded or an error received.
  ///   - localUrl: Downloaded publication URL.
  ///   - downloadTask: `URLSessionDownloadTask` that downloaded the publication.
  ///   - error: `NSError` if any.
  @objc func fulfill(_ file: URL, completion: @escaping (_ localUrl: URL?, _ error: NSError?) -> Void) {
    self.lcpService.acquirePublication(from: file) { result in
      do {
        let publication = try result.get()
        completion(publication.localURL, nil)
      } catch {
        let domain = "LCP fulfillment error"
        let code = NYPLErrorCode.lcpDRMFulfillmentFail.rawValue
        let errorDescription = (error as? LCPError)?.errorDescription ?? error.localizedDescription
        let nsError = NSError(domain: domain, code: code, userInfo: [
          NSLocalizedDescriptionKey: errorDescription as Any
        ])
        completion(nil, nsError)
      }
    }
  }
}

extension LCPLibraryService: LCPAuthenticationDelegate {
  
  /// Authenticate with passphrase.
  /// The function calls the callback set for document ID in the license
  /// - Parameters:
  ///   - license: Information to show to the user about the license being opened.
  ///   - passphrase: License passphrase
  func authenticate(_ license: LCPAuthenticatedLicense, with passphrase: String) {
    guard let callback = authenticationCallbacks.removeValue(forKey: license.document.id) else {
      return
    }
    callback(passphrase)
  }
  
  /// Cancel authentication. The function removes authentication callback associated with the license document ID
  /// - Parameter license:Information to show to the user about the license being opened.
  func didCancelAuthentication(of license: LCPAuthenticatedLicense) {
    guard let callback = authenticationCallbacks.removeValue(forKey: license.document.id) else {
      return
    }
    callback(nil)
  }
}

#endif
