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
  
  /// Downloads license file for the book associated with the given asset, validates it, extracts encrypted `AES` key, and decrypts it
  /// using our private key.
  ///
  /// - Note:
  /// We need to download license every time the user attempts to open book for reading. Upon downloading
  /// the license, we validate it and extract the encrypted `AES` key for unlocking content. The key itself
  /// needs to be decrypted before it can be used.
  ///
  /// - Parameters:
  ///   - asset: File Asset (NYPLBook file)
  ///   - completion: ProtectedAsset Tuple or `Publication.OpeningError`
  func handleAsset(asset: FileAsset,
                   fetcher: Fetcher,
                   completion: @escaping ProtectedAssetCompletion) {
    
    let license = NYPLAxisLicenseService(
      axisItemDownloader: downloader, cypher: decryptor.cypher,
      errorLogger: NYPLAxisErrorLogsAdapter(), parentDirectory: asset.url)
    
    license.extractAESKey { (result) in
      switch result {
      case .success(let key):
        let protectedAsset = self.getProtecedAsset(
          from: asset, key: key, fetcher: fetcher)
        completion(.success(protectedAsset))
      case .failure(let error):
        completion(.failure(.forbidden(error)))
      }
    }
  }
  
  /// Generates ProtectedAsset from given asset
  /// - Parameters:
  ///   - asset: File Asset (NYPLBook file)
  ///   - key: AES key provided by Axis to unlock book content
  ///   - completion: ProtectedAsset Tuple or `Publication.OpeningError`
  private func getProtecedAsset(from asset: FileAsset,
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
