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
import ReadiumLCP
import NYPLAudiobookToolkit

/// LCP Audiobooks helper class
@objc class LCPAudiobooks: NSObject {
    
  private let audiobookUrl: URL
  private let lcpService = LCPLibraryService()
  private let streamer: Streamer
  
  /// Distributor key - one can be found in `NYPLBook.distributor` property
  @objc static let distributorKey = "lcp"
  
  /// Initialize for an LCP audiobook
  /// - Parameter audiobookUrl: must be a file with `.lcpa` extension
  @objc init?(for audiobookUrl: URL) {
    // Check contentProtection is in place
    guard let contentProtection = lcpService.contentProtection else {
      return nil
    }
    self.audiobookUrl = audiobookUrl
    self.streamer = Streamer(contentProtections: [contentProtection])
  }
  
  /// Content dictionary for `AudiobookFactory`
  @objc func contentDictionary(completion: @escaping (_ json: NSDictionary?, _ error: NSError?) -> ()) {
    let manifestPath = "manifest.json"
    let asset = FileAsset(url: self.audiobookUrl)
    streamer.open(asset: asset, allowUserInteraction: false) { result in
      do {
        let publication = try result.get()
        let resourse = publication.get(manifestPath)
        let json = try resourse.readAsJSON().get()
        completion(json as NSDictionary, nil)
      } catch {
        NYPLErrorLogger.logError(error, summary: "Error reading LCP \(manifestPath) file")
        completion(nil, LCPAudiobooks.nsError(for: error))
      }
    }
  }
  
  /// Check if the book is LCP audiobook
  /// - Parameter book: audiobook
  /// - Returns: `true` if the book is an LCP DRM protected audiobook, `false` otherwise
  @objc static func canOpenBook(_ book: NYPLBook) -> Bool {
    book.defaultBookContentType() == .audiobook && book.distributor == distributorKey
  }

  /// Creates an NSError for Objective-C code
  /// - Parameter error: Error object
  /// - Returns: NSError object
  private static func nsError(for error: Error) -> NSError {
    let description = (error as? LCPError)?.errorDescription ?? error.localizedDescription
    return NSError(domain: "SimplyE.LCPAudiobooks", code: 0, userInfo: [
      NSLocalizedDescriptionKey: description
    ])
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
    let asset = FileAsset(url: self.audiobookUrl)
    streamer.open(asset: asset, allowUserInteraction: false) { result in
      do {
        let publication = try result.get()
        let resource = publication.get(url.path)
        let data = try resource.read().get()
        try data.write(to: resultUrl)
        completion(nil)
      } catch {
        NYPLErrorLogger.logError(error, summary: "Error decrypting LCP audio file \(url)")
        completion(LCPAudiobooks.nsError(for: error))
      }
    }
  }
}

#endif
