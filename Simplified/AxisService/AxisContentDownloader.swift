//
//  AxisContentDownloader.swift
//  Simplified
//
//  Created by Raman Singh on 2021-04-01.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

struct AxisContentDownloader {
  
  func downloadContent(from url: URL,
                       completion: @escaping (Result<Data, Error>) -> Void) {
    
    let downloadError = NSError(domain: "Failed downloading license",
                                code: 500,
                                userInfo: nil)
    
    _ = NYPLNetworkExecutor.shared.GET(url) { (data, response, error) in
      if let error = error {
        completion(.failure(error))
        return
      }
      
      if let response = response as? HTTPURLResponse,
        !(200...299).contains(response.statusCode) {
        completion(.failure(downloadError))
        return
      }
      
      if let data = data {
        completion(.success(data))
        return
      }
      
      completion(.failure(downloadError))
    }
  }
  
}
