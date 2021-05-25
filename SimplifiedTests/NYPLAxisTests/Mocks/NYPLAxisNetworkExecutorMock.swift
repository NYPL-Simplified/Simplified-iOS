//
//  NYPLAxisNetworkExecutorMock.swift
//  OpenEbooksTests
//
//  Created by Raman Singh on 2021-05-17.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//
import Foundation
@testable import SimplyE

class NYPLAxisNetworkExecutorMock: NYPLAxisNetworkExecutor {

  var deinitialzed: (() -> Void)?
  var didReceiveDownloadRequest: ((URLRequest) -> Void)?
  let networkExecutor: NYPLRequestExecutorMock

  init(executor: NYPLRequestExecutorMock = NYPLRequestExecutorMock()) {
    self.networkExecutor = executor
    super.init(networkExecutor: executor)
  }

  override func GET(_ request: URLRequest,
                    completion: @escaping (Result<Data, Error>) -> Void) -> URLSessionDataTask {
    didReceiveDownloadRequest?(request)
    return super.GET(request, completion: completion)
  }

  func setSucceedingUrls(_ urls: [URL]) {
    networkExecutor.responseBodies = urls.reduce(into: [:]) {
      $0[$1] = "some data"
    }
  }

  @discardableResult
  func withDefaultSucceedingUrls() -> NYPLAxisNetworkExecutorMock {
    let succeedingUrls = (Array(1...3) + Array(5...15)).compactMap {
      URL(string: "https://nypl.org/\($0)")
    }
    self.setSucceedingUrls(succeedingUrls)
    return self
  }

  deinit {
    deinitialzed?()
  }

}
