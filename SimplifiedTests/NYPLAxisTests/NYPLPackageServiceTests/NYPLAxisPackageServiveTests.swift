//
//  NYPLAxisPackageServiveTests.swift
//  OpenEbooksTests
//
//  Created by Raman Singh on 2021-05-18.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import XCTest
@testable import SimplyE

class NYPLAxisPackageServiveTests: XCTestCase {
  
  private let contentDownloader = NYPLAxisContentDownloaderMock()
  private let keysProvider = NYPLAxisKeysProvider()
  private let baseURL = URL(string: "www.mock.com")!
  private let assetWriter = AssetWriterMock()
  private let progressListener = NYPLAxisProgressListenerMock()
  
  lazy private var itemDownloader: NYPLAxisItemDownloader = {
    return NYPLAxisItemDownloader(
      assetWriter: assetWriter, downloader: contentDownloader)
  }()
  
  lazy private var downloadsDirectory: URL = {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory.appendingPathComponent("NYPLAxisLicenseServiceTests")
  }()
  
  lazy private var containerURL: URL = {
    return self.downloadsDirectory
      .appendingPathComponent(keysProvider.containerDownloadEndpoint)
  }()
  
  lazy private var containerData: Data = {
    let itemURL = Bundle(for: NYPLAxisPackageServiveTests.self)
      .url(forResource: "container", withExtension: "xml")!
    return try! Data(contentsOf: itemURL)
  }()
  
  lazy private var packageData: Data = {
    let itemURL = Bundle(for: NYPLAxisPackageServiveTests.self)
      .url(forResource: "package", withExtension: "opf")!
    return try! Data(contentsOf: itemURL)
  }()
  
  override func tearDown() {
    super.tearDown()
    try? FileManager.default.removeItem(at: downloadsDirectory)
  }
  
  func testPackageServiceShouldNotContiunueWithoutContainerFile() {
    let terminationExpectation = self.expectation(
      description: "Package download should terminate if no container file found")
    
    let packageService = NYPLAxisPackageService(
      axisItemDownloader: itemDownloader, axisKeysProvider: keysProvider,
      baseURL: baseURL, parentDirectory: downloadsDirectory)
    
    NYPLAxisTaskAggregator()
      .addTasks(packageService.makeDownloadPackageContentTasks())
      .run()
      .onCompletion { result in
        switch result {
        case .success:
          XCTFail()
        case .failure(let error):
            switch error {
            case .invalidContainerFile:
              terminationExpectation.fulfill()
            default:
              break
            }
        }
      }
    
    waitForExpectations(timeout: 3, handler: nil)
  }
  
}
