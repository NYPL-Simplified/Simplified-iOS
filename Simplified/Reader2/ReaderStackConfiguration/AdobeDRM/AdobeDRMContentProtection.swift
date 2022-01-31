//
//  AdobeDRMContentProtection.swift
//  Simplified
//
//  Created by Vladimir Fedorov on 20.01.2021.
//  Copyright © 2021 NYPL. All rights reserved.
//

#if FEATURE_DRM_CONNECTOR

import Foundation
import R2Shared

class AdobeDRMContentProtection: ContentProtection {
  func open(asset: PublicationAsset,
            fetcher: Fetcher,
            credentials: String?,
            allowUserInteraction: Bool,
            sender: Any?,
            completion: @escaping (CancellableResult<ProtectedAsset?,
                                                     Publication.OpeningError>) -> Void) {
    
    // Publication asset must be a FileAsset, as we are opening a file
    // If not, we can't open and use Adobe DRM
    guard let fileAsset = asset as? FileAsset else {
      NYPLErrorLogger.logError(withCode: .adobeDRMFulfillmentFail,
                               summary: "Missing file asset while opening Adobe DRM epub",
                               metadata: [
                                "asset type": type(of: asset),
                                "asset name": asset.name,
                                "allowUserInteraction": allowUserInteraction
                               ])
      completion(.failure(.unsupportedFormat))
      return
    }
    
    guard let encryptionData = fetcher.fetchAdobeEncryptionData() else {
      // .success(nil) means it is not an asset protected with Adobe DRM
      // Streamer continues to iterate over available ContentProtections
      // Don't use .failure(...) in this case, it means .epub is protected with this type of Content Protection,
      // but it failed to open it.
      completion(.success(nil))
      return
    }

    let adobeFetcher = AdobeDRMFetcher(url: fileAsset.url, fetcher: fetcher, encryptionData: encryptionData)
    let protectedAsset = ProtectedAsset(
      asset: asset,
      fetcher: adobeFetcher,
      onCreatePublication: { _, _, _, services in
        services.setContentProtectionServiceFactory { pubServiceContext in
          NYPLAdobeContentProtectionService(context: pubServiceContext)
        }
      }
    )
    completion(.success(protectedAsset))
  }
}

private extension Fetcher {
  func fetchAdobeEncryptionData() -> Data? {
    // The `META-INF` directory is a part of EPUBs structure, and Adobe DRM
    // expects to find encryption algorithms for each .epub file in it.
    // Other DRM systems may look for other files to underestand the type of
    // content protection: for example, LCP is looking for an .lcpl file.
    let encryptionRelativePath = "META-INF/encryption.xml"

    // If the encryption.xml file doesn't exist, this is definitely
    // not an Adobe DRM .epub...
    let resource = get("/" + encryptionRelativePath)

    guard let data = try? resource.read().get() else {
      // ... although let's attempt without the leading slash, since that
      // expectation has been changing on the R2 side
      let resource = get(encryptionRelativePath)
      return try? resource.read().get()
    }

    return data
  }
}

#endif
