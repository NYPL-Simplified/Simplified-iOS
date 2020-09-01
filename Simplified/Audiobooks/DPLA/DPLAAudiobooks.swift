//
//  DPLA.swift
//  SimplyE
//
//  Created by Vladimir Fedorov on 01.09.2020.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

/// DPLA Audiobooks DRM helper class
class DPLAAudiobooks {
  
  /// Certificate URL 
  static let certificateUrl = URL(string: "https://listen.cantookaudio.com/.well-known/jwks.json")!
  
  /// Requests and returns a private key for audiobooks DRM
  /// - Parameter completion: private key data
  static func drmKey(completion: @escaping (_ privateKeyData: Data?, _ error: Error?) -> ()) {
    let task = URLSession.shared.dataTask(with: DPLAAudiobooks.certificateUrl) { (data, response, error) in
      // In case of an error
      if let error = error {
        OperationQueue.main.addOperation {
          completion(nil, error)
        }
        return
      }
      // TODO: Add error logging for JSONDecoder
      guard let data = data,
        let jwkResponse = try? JSONDecoder().decode(JWKResponse.self, from: data),
        let jwk = jwkResponse.keys.first,
        let privateKey = jwk.privateRSAKey
        else {
          OperationQueue.main.addOperation {
            completion(nil, nil)
          }
          return
        }
      // All is good
      OperationQueue.main.addOperation {
        completion(privateKey, nil)
      }
    }
    task.resume()
  }
}
