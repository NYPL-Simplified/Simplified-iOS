//
//  NYPLAxisContentDownloaderMock.swift
//  OpenEbooksTests
//
//  Created by Raman Singh on 2021-05-18.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
@testable import SimplyE

class NYPLAxisContentDownloaderMock: NYPLAxisContentDownloading {
  
  enum MockDownloaderError: Error {
    case someError
  }
  
  var desiredResult: Result<Data, Error> = .failure(MockDownloaderError.someError)
  var didReceiveRequestForUrl: ((URL) -> Void)?
  
  func downloadItem(from url: URL, _ completion: @escaping (Result<Data, Error>) -> Void) {
    didReceiveRequestForUrl?(url)
    completion(desiredResult)
  }
  
  func mockDownloadFailure() {
    desiredResult = .failure(
      NYPLAxisContentDownloaderMock.MockDownloaderError.someError)
  }
  
  func mockDownloadSuccess() {
    let data = "Some data".data(using: .utf8)!
    desiredResult = .success(data)
  }
  
  func cancelAllDownloads(withError error: Error) {
    desiredResult = .failure(error)
  }
  
}
