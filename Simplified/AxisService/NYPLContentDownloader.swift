//
//  NYPLContentDownloader.swift
//  Simplified
//
//  Created by Raman Singh on 2021-04-06.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

struct NYPLContentDownloader {
  
  let networkExecutor: NYPLNetworkExecutor
  
  /// Downloads content from given url
  /// - Parameters:
  ///   - url: URL from which content should be downloaded
  ///   - completion: Result object containing either data or error
  func downloadContent(from url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
    networkExecutor.GET(url) { (result) in
      switch result {
      case .success(let data, let response):
        guard
          let response = response as? HTTPURLResponse,
          (200...299).contains(response.statusCode)
          else {
            let downloadError = NSError(
              domain: "Failed downloading content from \(url)",
              code: 500,
              userInfo: nil)
            completion(.failure(downloadError))
            return
        }
        
        completion(.success(data))
      case .failure(let error, _):
        completion(.failure(error))
      }
    }
  }
  
}
