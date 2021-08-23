//
//  NYPLAxisProtectedAssetHandler.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-05-18.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
import R2Shared
import R2Streamer

typealias ProtectedAssetCompletion = (Result<ProtectedAsset, Publication.OpeningError>) -> Void

protocol NYPLAxisProtectedAssetHandling {
  func handleAsset(asset: FileAsset, fetcher: Fetcher,
                   completion: @escaping ProtectedAssetCompletion)
}

struct NYPLAxisProtectedAssetHandler: NYPLAxisProtectedAssetHandling {
  
  private let bookReadingAdapter: NYPLAxisBookReadingAdapter
  
  init?(adapter: NYPLAxisBookReadingAdapter? = NYPLAxisBookReadingAdapter()) {
    guard let adapter = adapter else {
      return nil
    }
    self.bookReadingAdapter = adapter
  }
  
  /// Opens asset using `NYPLAxisBookReadingAdapter` which first downloads license, validates it,
  /// extracts encrypted `AES` key from license, decrypts it, and uses the decrypted key to provide data to
  /// the reader.
  func handleAsset(asset: FileAsset, fetcher: Fetcher,
                   completion: @escaping ProtectedAssetCompletion) {
    
    bookReadingAdapter
      .handleAsset(asset: asset, fetcher: fetcher, completion: completion)
  }
  
}

