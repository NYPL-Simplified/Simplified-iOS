//
//  NYPLBook+DistributorChecks.swift
//  Simplified
//
//  Created by Ettore Pasquini on 10/6/20.
//  Copyright © 2020 NYPL. All rights reserved.
//

import Foundation

#if FEATURE_OVERDRIVE_AUTH
import OverdriveProcessor
#endif

extension NYPLBook {

  /// Determines if the download of this book should complete successfully
  /// given the received content type.
  ///
  /// - parameter downloadedContentType: The Content-Type returned by the server response.
  /// - returns `true` if the download should be completed.
  @objc(canCompleteDownloadWithContentType:)
  func canCompleteDownload(withContentType downloadedContentType: String) -> Bool {
    let downloadedType = downloadedContentType.lowercased()

    // if the content type matches one of the supported types exactly, go ahead
    if NYPLOPDSAcquisitionPath.supportedTypes().contains(downloadedType) {
      return true
    }

    #if FEATURE_AUDIOBOOKS && FEATURE_OVERDRIVE_AUTH
    // Overdrive may return a response whose Content-Type doesn't match the
    // one that was promised in this book's OPDS document
    if distributor?.lowercased() == OverdriveAPI.distributorKey.lowercased() {
      // if we original acquisition for this book matches, that's good enough
      if defaultAcquisition()?.type.lowercased() == ContentTypeOverdriveAudiobook {
        return true
      }

      // This is a last resort added from empirical observations. Overdrive
      // seems to return `application/json` and in that case the download
      // appears to be correct and it is playable.
      if downloadedType == ContentTypeOverdriveAudiobookActual {
        return true
      }
    }
    #endif
    
    return false
  }
}
