//
//  NYPLContentDownloaderTests.swift
//  OpenEbooksTests
//
//  Created by Raman Singh on 2021-04-26.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import XCTest
@testable import SimplyE

class NYPLContentDownloaderTests: XCTestCase {
  
  private let allSucceedingURLs = Array(5...15).compactMap { URL(string: "https://nypl.org/\($0)")}
  private let urlsWithOneFailure = Array(1...10).compactMap { URL(string: "https://nypl.org/\($0)")}
  
  /// When an item fails to download the first time, it must be attempted to download again twice
  func testFailedItemDownloadShouldBeReAttemptedToDownload() {
    let expectation = XCTestExpectation(
      description: "Failed download request should be reattempted twice")
    expectation.expectedFulfillmentCount = 3
    let executor = MockAxisNetworkExecutor()
    let itemURL = URL(string: "https://nypl.org/4")!
    executor.didReceiveDownloadRequest = {
      if itemURL == $0.url {
        expectation.fulfill()
      }
    }
    
    let contentDownloader = NYPLAxisContentDownloader(networkExecuting: executor)
    contentDownloader.downloadItem(from: itemURL) { _ in }
    wait(for: [expectation], timeout: 4)
  }
  
  /// When an item fails to download after 2 more attempts, all subsequent items should be prevented from
  /// downloading
  func testFailedItemDownloadShouldPreventFurtherDownloads() {
    let expectation = XCTestExpectation(
      description: "Failed download request should prevent further downloads")
    expectation.isInverted = true
    
    let executor = MockAxisNetworkExecutor()
    let failingDownloadURL = URL(string: "https://nypl.org/4")!
    
    let contentDownloader = NYPLAxisContentDownloader(networkExecuting: executor)
    
    let itemDownloadFailed = {
      for url in self.allSucceedingURLs {
        contentDownloader.downloadItem(from: url) { (result) in
          expectation.fulfill()
        }
      }
    }
    
    contentDownloader.downloadItem(from: failingDownloadURL) { (result) in
      switch result {
      case .success:
        print("download succeeded from \(failingDownloadURL.absoluteString)")
        XCTFail()
      case .failure:
        print("download failed from \(failingDownloadURL.absoluteString)")
        itemDownloadFailed()
      }
    }
    
    wait(for: [expectation], timeout: 10)
  }
  
  /// When downloading multiple items, If none of the download fails, NYPLContentDownloader should not
  /// stop until all the items are downloaded.
  func testAllTasksShouldExecuteIfNoFailureOccurs() {
    let expectation = XCTestExpectation(
      description: "If no failure occurs, all requests should be executed!")
    expectation.expectedFulfillmentCount = allSucceedingURLs.count
    
    let contentDownloader = NYPLAxisContentDownloader(networkExecuting: MockAxisNetworkExecutor())
    
    for url in allSucceedingURLs {
      contentDownloader.downloadItem(from: url) { (result) in
        switch result {
        case .success:
          expectation.fulfill()
        case .failure:
          XCTFail()
        }
      }
    }

    wait(for: [expectation], timeout: 5)
  }
  
  /// NYPLContentDownloader and its network executor should deinitialize successfully.
  func testNetworkExecutorAndContentDownloaderShouldDeinitUponCompletion() {
    let expectation = XCTestExpectation(
      description: "NYPLAxisContentDownloader and NYPLAxisNetworkExecutor should deinitialize upon completion")
    expectation.expectedFulfillmentCount = 2
    
    var customContentDownloader: CustomNYPLContentDownloader? = CustomNYPLContentDownloader(networkExecuting: MockAxisNetworkExecutor())
    
    customContentDownloader?.deinitialzed = {
      expectation.fulfill()
    }
    
    if let executor = customContentDownloader?.networkExecutor as? MockAxisNetworkExecutor {
      executor.deinitialzed = {
        expectation.fulfill()
      }
    }
    
    for url in allSucceedingURLs {
      customContentDownloader?.downloadItem(from: url) { (_) in }
    }
    
    customContentDownloader = nil
    
    wait(for: [expectation], timeout: 10)
  }
  
  /// NYPLContentDownloader and its network executor should deinitialize successfully.
  func testNetworkExecutorAndContentDownloaderShouldDeinitUponFailure() {
    let expectation = XCTestExpectation(
      description: "NYPLAxisContentDownloader and NYPLAxisNetworkExecutor should deinitialize upon failure")
    expectation.expectedFulfillmentCount = 2
    
    
    var customContentDownloader: CustomNYPLContentDownloader? = CustomNYPLContentDownloader(networkExecuting: MockAxisNetworkExecutor())
    
    customContentDownloader?.deinitialzed = {
      expectation.fulfill()
    }
    
    if let executor = customContentDownloader?.networkExecutor as? MockAxisNetworkExecutor {
      executor.deinitialzed = {
        expectation.fulfill()
      }
    }
    
    for url in urlsWithOneFailure {
      customContentDownloader?.downloadItem(from: url) { (_) in }
    }
    
    customContentDownloader = nil
    
    wait(for: [expectation], timeout: 10)
  }

}

private class MockAxisNetworkExecutor: NYPLAxisNetworkExecutor {
  
  var deinitialzed: (() -> Void)?
  var didReceiveDownloadRequest: ((URLRequest) -> Void)?
  
  init() {
    let executor = NYPLRequestExecutorMock()
    let succeeding = Array(1...3) + Array(5...15)
    executor.responseBodies = succeeding.reduce(into: [:], {
      $0[URL(string: "https://nypl.org/\($1)")!] = "Some data"
    })
    super.init(networkExecutor: executor)
  }
  
  override func GET(_ request: URLRequest,
                    completion: @escaping (Result<Data, Error>) -> Void) -> URLSessionDataTask {
    didReceiveDownloadRequest?(request)
    return super.GET(request, completion: completion)
  }
  
  deinit {
    deinitialzed?()
  }
  
}

private class CustomNYPLContentDownloader: NYPLAxisContentDownloader {
  var deinitialzed: (() -> Void)?
  
  deinit {
    deinitialzed?()
  }
}
