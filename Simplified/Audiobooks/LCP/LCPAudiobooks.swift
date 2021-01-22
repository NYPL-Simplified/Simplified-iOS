//
//  LCPAudiobooks.swift
//  Simplified
//
//  Created by Vladimir Fedorov on 16.11.2020.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

#if LCP

import Foundation
import R2Shared
import R2Streamer
import NYPLAudiobookToolkit

/// LCP Audiobooks helper class
@objc class LCPAudiobooks: NSObject {
    
  private let audiobookUrl: URL
  private let lcpService = LCPLibraryService()

  /// .lcpa archive container
//  private let container: Container
  private let publication: Publication?
  

  /// Distributor key - one can be found in `NYPLBook.distributor` property
  @objc static let distributorKey = "lcp"
  
  /// Initialize for an LCP audiobook
  /// - Parameter audiobookUrl: must be a file with `.lcpa` extension
  @objc init?(for audiobookUrl: URL) {
    self.audiobookUrl = audiobookUrl
    self.publication = nil
  }
  
  /// Content dictionary for `AudiobookFactory`
  @objc func contentDictionary() -> NSDictionary? {
    let manifestPath = "manifest.json"
    do {
      // Relative path inside the audiobook
      
//      let data = try container.data(relativePath: manifestPath)
//      let publicationObject = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? NSDictionary
      
      guard let result = publication?.get(manifestPath).readAsJSON() else {
        return nil
      }
      let publicationObject = try result.get()
      return publicationObject as NSDictionary
    } catch {
      NYPLErrorLogger.logError(error, summary: "Error reading LCP audiobook")
      return nil
    }
  }
  
  /// Check if the book is LCP audiobook
  /// - Parameter book: audiobook
  /// - Returns: `true` if the book is an LCP DRM protected audiobook, `false` otherwise
  @objc static func canOpenBook(_ book: NYPLBook) -> Bool {
    book.defaultBookContentType() == .audiobook && book.distributor == distributorKey
  }

}

/// DRM Decryptor for LCP audiobooks
extension LCPAudiobooks: DRMDecryptor {

  /// Decrypt protected file
  /// - Parameters:
  ///   - url: encrypted file URL.
  ///   - resultUrl: URL to save decrypted file at.
  ///   - completion: decryptor callback with optional `Error`.
  func decrypt(url: URL, to resultUrl: URL, completion: @escaping (Error?) -> Void) {
  }
  
  /// Load `DRMLicense` license for audiobook once
  /// - Parameter completion: `LCPError`, if any
//  private func loadLicense(completion: @escaping (_ license: DRMLicense?, _ error: Error?) -> Void) {
//    lcpService.loadPublication(at: audiobookUrl, drm: DRM(brand: .lcp)) { result in
//      switch result {
//      case .success(let drm):
//        completion(drm?.license, nil)
//      case .failure(let error):
//        completion(nil, error)
//      case .cancelled:
//        completion(nil, nil)
//      }
//    }
//  }
}

#endif
