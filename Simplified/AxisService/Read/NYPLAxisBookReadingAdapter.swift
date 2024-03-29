//
//  NYPLAxisBookReadingAdapter.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-06-23.
//  Copyright © 2021 NYPL. All rights reserved.
//

import Foundation
import NYPLAxis
import R2Shared
import R2Streamer

struct NYPLAxisBookReadingAdapter {
  private let decryptor: NYPLAxisContentDecrypting

  init?(decryptor: NYPLAxisContentDecrypting? = NYPLAxisContentDecryptor()) {
    guard let decryptor = decryptor else {
      return nil
    }
    
    self.decryptor = decryptor
  }
  
  /// Given an asset on disk, obtains the R2 ProtectedAsset needed to open
  /// a book for reading.
  ///
  /// - Parameters:
  ///   - asset: R2 book asset on disk associated to a NYPLBook
  ///   - completion: Returns a R2 tuple containing the PublicationAsset and
  ///   its Content Protection, or an error.
  func open(asset: FileAsset,
            fetcher: Fetcher,
            completion: @escaping ProtectedAssetCompletion) {
    
    let licenseService = NYPLAxisLicenseExtractService(
      errorLogger: NYPLAxisErrorLogsAdapter(),
      parentDirectory: asset.url)
    
    // we decrypt the encrypted key (used to unlock content) and use that
    // to get the ProtectedAsset
    licenseService.extractAESKeyFromDisk { result in
      switch result {
      case .success(let key):
        // If it succeeded and returned data is nil,
        // the asset is not protected by AxisDRM.
        guard let keyData = key else {
          completion(.success(nil))
          return
        }
        let protectedAsset = self.getProtectedAsset(
          from: asset, key: keyData, fetcher: fetcher)
        completion(.success(protectedAsset))
      case .failure(let error):
        completion(.failure(.forbidden(error)))
      }
    }
  }
  
  /// Generates ProtectedAsset from given asset
  /// - Parameters:
  ///   - asset: R2 book asset on disk associated to a NYPLBook
  ///   - key: Key provided by Axis to unlock book content
  ///   - fetcher: R2 object used to fetch publication data
  private func getProtectedAsset(from asset: FileAsset,
                                 key: Data,
                                 fetcher: Fetcher) -> ProtectedAsset {
    
    let transformingFetcher = TransformingFetcher(fetcher: fetcher) {
      return decryptor.decrypt(resource: $0, withKey: key)
    }
    
    let protectedAsset = ProtectedAsset(asset: asset,
                                        fetcher: transformingFetcher,
                                        onCreatePublication: nil)
    return protectedAsset
  }
}
