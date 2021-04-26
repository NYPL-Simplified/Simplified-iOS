//
//  NYPLAxisNetworkExecuting.swift
//  Simplified
//
//  Created by Raman Singh on 2021-04-26.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

protocol NYPLAxisNetworkExecuting {
  var requestTimeout: TimeInterval { get }
  func GET(_ request: URLRequest,
           completion: @escaping (Result<Data, Error>) -> Void) -> URLSessionDataTask
}
