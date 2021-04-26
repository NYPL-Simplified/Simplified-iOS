//
//  NYPLAxisNetworkExecutor.swift
//  Simplified
//
//  Created by Raman Singh on 2021-04-22.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

class NYPLAxisNetworkExecutor: NYPLAxisNetworkExecuting {
  
  private let requestExecutor: NYPLRequestExecuting
  var requestTimeout: TimeInterval { return requestExecutor.requestTimeout }
  
  init(
    networkExecutor: NYPLRequestExecuting = NYPLNetworkExecutor(
    cachingStrategy: .ephemeral)) {
    self.requestExecutor = networkExecutor
  }
  
  func GET(_ request: URLRequest,
           completion: @escaping (Result<Data, Error>) -> Void) -> URLSessionDataTask {
    
    let task = requestExecutor.executeRequest(request) { (result) in
      switch result {
      case .success(let data, _):
        completion(.success(data))
      case .failure(let error, _):
        completion(.failure(error))
      }
    }
    
    return task
  }

}
