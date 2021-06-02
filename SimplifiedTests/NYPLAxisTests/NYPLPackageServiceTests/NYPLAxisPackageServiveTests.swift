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
    
    progressListener.didTerminate = {
      terminationExpectation.fulfill()
    }
    itemDownloader.delegate = progressListener
    
    packageService.downloadPackageContent()
    
    waitForExpectations(timeout: 3, handler: nil)
  }
  
  func testPackageServiceShouldNotContinueUponPackageDownloadFailure() {
    let terminationExpectation = self.expectation(
      description: "Package download should terminate if package file download fails")
    
    let packageService = NYPLAxisPackageService(
      axisItemDownloader: itemDownloader, axisKeysProvider: keysProvider,
      baseURL: baseURL, parentDirectory: downloadsDirectory)
    
    writeAssetForContainer()
    contentDownloader.mockDownloadFailure()
    
    progressListener.didTerminate = {
      terminationExpectation.fulfill()
    }
    itemDownloader.delegate = progressListener
    packageService.downloadPackageContent()
    
    waitForExpectations(timeout: 3, handler: nil)
  }
  
  func testPackageServiceShouldNotContinueUponPackageWriteFailure() {
    let terminationExpectation = self.expectation(
      description: "Package download should terminate if package file write fails")
    let writeExpectation = self.expectation(
      description: "PackageService should try to write package file")
    
    let packageService = NYPLAxisPackageService(
      axisItemDownloader: itemDownloader, axisKeysProvider: keysProvider,
      baseURL: baseURL, parentDirectory: downloadsDirectory)
    
    writeAssetForContainer()
    contentDownloader.desiredResult = .success(packageData)
    assetWriter.mockingFailure()
    
    progressListener.didTerminate = {
      terminationExpectation.fulfill()
    }
    
    assetWriter.willWriteAsset = {
      writeExpectation.fulfill()
    }
    
    itemDownloader.delegate = progressListener
    packageService.downloadPackageContent()
    
    waitForExpectations(timeout: 3, handler: nil)
  }
  
  func testPackageServiceShouldDownloadLinksFromPackageFile() {
    let writeExpectation = self.expectation(
      description: "PackageService should try to write package file")
    
    writeExpectation.expectedFulfillmentCount = 4
    
    let itemDownloader = NYPLAxisItemDownloader(
      assetWriter: NYPLAssetWriter(), downloader: contentDownloader)
    let packageService = NYPLAxisPackageService(
      axisItemDownloader: itemDownloader, axisKeysProvider: keysProvider,
      baseURL: baseURL, parentDirectory: downloadsDirectory)
    
    writeAssetForContainer()
    contentDownloader.desiredResult = .success(packageData)
    
    progressListener.didTerminate = {
      XCTFail()
    }
    
    itemDownloader.delegate = progressListener
    packageService.downloadPackageContent()
    let packageURL = downloadsDirectory.appendingPathComponent("ops/package.opf")
    let chapter1URL = downloadsDirectory.appendingPathComponent("ops/xhtml/ch01.html")
    let chapter2URL = downloadsDirectory.appendingPathComponent("ops/xhtml/ch02.html")
    let chapter3URL = downloadsDirectory.appendingPathComponent("ops/xhtml/ch03.html")
    itemDownloader.dispatchGroup.notify(queue: .global()) {
      if self.fileExists(at: packageURL) {
        writeExpectation.fulfill()
      }
      if self.fileExists(at: chapter1URL) {
        writeExpectation.fulfill()
      }
      if self.fileExists(at: chapter2URL) {
        writeExpectation.fulfill()
      }
      if self.fileExists(at: chapter3URL) {
        writeExpectation.fulfill()
      }
    }
    
    waitForExpectations(timeout: 3, handler: nil)
  }

  private func writeAssetForContainer() {
    let itemURL = Bundle(for: NYPLAxisPackageServiveTests.self)
      .url(forResource: "container", withExtension: "xml")!
    let containerData = try! Data(contentsOf: itemURL)
    try! NYPLAssetWriter().writeAsset(containerData, atURL: containerURL)
  }
  
  private func fileExists(at url: URL) -> Bool {
    return FileManager.default.fileExists(atPath: url.path)
  }
  
}
