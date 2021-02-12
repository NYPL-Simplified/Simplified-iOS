//
//  AdobeDRMContentProtection.swift
//  Simplified
//
//  Created by Vladimir Fedorov on 20.01.2021.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
import R2Shared

#if FEATURE_DRM_CONNECTOR

class AdobeDRMContentProtection: ContentProtection {
  func open(asset: PublicationAsset, fetcher: Fetcher, credentials: String?, allowUserInteraction: Bool, sender: Any?, completion: @escaping (CancellableResult<ProtectedAsset?, Publication.OpeningError>) -> Void) {
    
    // Publication asset must be a FileAsset, as we are opening a file
    // If not, we can't open and use Adobe DRM
    guard let fileAsset = asset as? FileAsset else {
      NYPLErrorLogger.logError(nil, summary: "AdobeDRMContentProtection.open expected asset of FileAsset type, received \(type(of: asset)))")
      completion(.failure(.unavailable(nil)))
      return
    }
    
    do {
      // META-INF is a part of .epub structure
      let encryptionPath = "META-INF/encryption.xml"
      let resource = fetcher.get(encryptionPath)
      let encryptionData = try resource.read().get()
      let adobeFetcher = AdobeDRMFetcher(url: fileAsset.url, fetcher: fetcher, encryptionData: encryptionData)
      let protectedAsset = ProtectedAsset(
        asset: asset,
        fetcher: adobeFetcher,
        onCreatePublication: nil
      )
      completion(.success(protectedAsset))
    } catch {
      // .success(nil) means it is not an asset protected with Adobe DRM
      // Streamer continues to iterate over available ContentProtections
      completion(.success(nil))
    }
    
  }
}

#endif
