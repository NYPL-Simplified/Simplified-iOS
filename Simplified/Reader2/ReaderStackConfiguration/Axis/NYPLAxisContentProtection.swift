//
//  NYPLAxisContentProtection.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-05-18.
//  Copyright © 2021 NYPL. All rights reserved.
//

import Foundation
import R2Shared
import R2Streamer

struct NYPLAxisContentProtection: ContentProtection {
  
  let protectedAssetOpener: NYPLAxisProtectedAssetOpening
  
  func open(asset: PublicationAsset, fetcher: Fetcher, credentials: String?,
            allowUserInteraction: Bool, sender: Any?,
            completion: @escaping (
              CancellableResult<ProtectedAsset?, Publication.OpeningError>) -> Void) {
    
    guard let asset = asset as? FileAsset else {
      completion(.failure(.notFound))
      return
    }
    
    protectedAssetOpener.openAsset(asset, fetcher: fetcher) { result in
      switch result {
      case .success(let protectedAsset):
        completion(.success(protectedAsset))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
}
