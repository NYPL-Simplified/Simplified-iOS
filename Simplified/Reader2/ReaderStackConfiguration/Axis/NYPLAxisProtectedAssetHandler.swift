//
//  NYPLAxisProtectedAssetOpener.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-05-18.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
import R2Shared
import R2Streamer

typealias ProtectedAssetCompletion = (Result<ProtectedAsset, Publication.OpeningError>) -> Void

protocol NYPLAxisProtectedAssetOpening {
  func openAsset(_ asset: FileAsset,
                 fetcher: Fetcher,
                 completion: @escaping ProtectedAssetCompletion)
}

struct NYPLAxisProtectedAssetOpener: NYPLAxisProtectedAssetOpening {
  
  private let bookReadingAdapter: NYPLAxisBookReadingAdapter
  
  init?(adapter: NYPLAxisBookReadingAdapter? = NYPLAxisBookReadingAdapter()) {
    guard let adapter = adapter else {
      return nil
    }
    self.bookReadingAdapter = adapter
  }
  
  /// Opens asset using the `bookReadingAdapter` instance property which first
  /// decrypts the encrypted key from disk, and uses the decrypted key to unlock
  ///  and provide data to the ereader.
  func openAsset(_ asset: FileAsset,
                 fetcher: Fetcher,
                 completion: @escaping ProtectedAssetCompletion) {
    
    bookReadingAdapter.openAsset(asset, fetcher: fetcher, completion: completion)
  }
  
}

