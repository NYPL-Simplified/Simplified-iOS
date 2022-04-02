//
//  NYPLAxisNetworkExecutor.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-06-23.
//  Copyright © 2021 NYPL. All rights reserved.
//

import Foundation
import NYPLAxis

class NYPLAxisNetworkExecutor: NYPLAxisNetworkExecuting {
  
  private let requestExecutor: NYPLRequestExecuting
  var requestTimeout: TimeInterval { return requestExecutor.requestTimeout }
  
  init() {
    self.requestExecutor = NYPLNetworkExecutor(
      credentialsProvider: NYPLUserAccount.sharedAccount(),
      cachingStrategy: .ephemeral)
  }
  
  func GET(_ request: URLRequest,
           completion: @escaping (Result<Data, Error>) -> Void) {
    
    requestExecutor.executeRequest(request) { (result) in
      switch result {
      case .success(let data, _):
        completion(.success(data))
      case .failure(let error, _):
        completion(.failure(error))
      }
    }
  }

}
