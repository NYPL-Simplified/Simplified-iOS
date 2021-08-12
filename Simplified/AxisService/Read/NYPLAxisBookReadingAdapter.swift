//
//  NYPLAxisBookReadingAdapter.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-06-23.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
import NYPLAxis
import R2Shared
import R2Streamer

struct NYPLAxisBookReadingAdapter {
  
  private let axisKeysProvider: NYPLAxisKeysProviding
  private let decryptor: NYPLAxisContentDecrypting
  private let downloader: NYPLAxisItemDownloading
  
  init?(axisKeysProvider: NYPLAxisKeysProviding = NYPLAxisKeysProvider(),
       decryptor: NYPLAxisContentDecrypting? = NYPLAxisContentDecryptor(),
       downloader: NYPLAxisItemDownloading = NYPLAxisItemDownloader(downloader: NYPLAxisContentDownloader(), errorLogger: NYPLAxisErrorLogsAdapter())
  ) {
    
    guard let decryptor = decryptor else {
      return nil
    }
    
    self.axisKeysProvider = axisKeysProvider
    self.decryptor = decryptor
    self.downloader = downloader
  }
  
  /// Given an asset on disk, obtains the R2 ProtectedAsset needed to open
  /// a book for reading.
  ///
  /// - Parameters:
  ///   - asset: R2 book asset on disk associated to a NYPLBook
  ///   - completion: Returns a R2 tuple containing the PublicationAsset and
  ///   its Content Protection, or an error.
  func openAsset(_ asset: FileAsset,
                 fetcher: Fetcher,
                 completion: @escaping ProtectedAssetCompletion) {
    
    let licenseService = NYPLAxisLicenseService(axisItemDownloader: downloader,
                                                cypher: decryptor.cypher,
                                                errorLogger: NYPLAxisErrorLogsAdapter(),
                                                parentDirectory: asset.url)
    
    // we decrypt the encrypted key (used to unlock content) and use that
    // to get the ProtectedAsset
    licenseService.extractAESKey { result in
      switch result {
      case .success(let key):
        let protectedAsset = self.getProtectedAsset(
          from: asset, key: key, fetcher: fetcher)
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
