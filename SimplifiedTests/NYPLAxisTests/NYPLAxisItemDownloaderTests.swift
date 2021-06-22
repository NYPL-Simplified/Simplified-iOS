//
//  NYPLAxisItemDownloaderTests.swift
//  OpenEbooksTests
//
//  Created by Raman Singh on 2021-05-18.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//
import XCTest
@testable import SimplyE

class NYPLAxisItemDownloaderTests: XCTestCase {
  
  private let contentDownloader = NYPLAxisContentDownloaderMock()
  private let someURL = URL(string: "www.mock.com")!
  private let someOtherURL = URL(string: "www.mock2.com")!
  
  lazy private var downloadsDirectory: URL = {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory.appendingPathComponent("NYPLAxisLicenseServiceTests")
  }()
  
  lazy private var weightProvider: NYPLAxisWeightProviding = {
    return NYPLAxisDownloadTaskWeightProviderMock(
      weights: [someURL: 0.4, someOtherURL: 0.2])
  }()
  

  
  func testDownloaderShouldWriteAssetUponSuccessfulDownload() {
    let writeExpectation = self.expectation(
      description: "Downloader should write asset upon successful download")
    
    let assetWriter = AssetWriterMock().mockingSuccess()
    assetWriter.willWriteAsset = {
      writeExpectation.fulfill()
    }
    
    let itemDownloader = NYPLAxisItemDownloader(
      assetWriter: assetWriter,
      downloader: contentDownloader)
    contentDownloader.mockDownloadSuccess()
    
    itemDownloader.downloadItem(from: someURL, at: downloadsDirectory) { _ in }
    
    waitForExpectations(timeout: 4, handler: nil)
  }
  
  func testDownloaderShouldNotUpdateProgressUponFailureDownloadingAsset() {
    let assetWriter = AssetWriterMock().mockingSuccess()
    
    let itemDownloader = NYPLAxisItemDownloader(
      assetWriter: assetWriter, downloader: contentDownloader,
      weightProvider: weightProvider)
    
    let progressListener = NYPLAxisProgressListenerMock()
    itemDownloader.delegate = progressListener
    XCTAssertEqual(progressListener.currentProgress, 0)
    
    contentDownloader.mockDownloadSuccess()
    itemDownloader.downloadItem(from: someURL, at: downloadsDirectory) { _ in }
    XCTAssertEqual(progressListener.currentProgress, 0.4)
    
    contentDownloader.mockDownloadFailure()
    itemDownloader.downloadItem(from: someOtherURL, at: downloadsDirectory) { _ in }
    XCTAssertEqual(progressListener.currentProgress, 0.4)
  }

  func testDownloaderShouldNotUpdateProgressUponFailureWritingAsset() {
    let assetWriter = AssetWriterMock().mockingFailure()
    
    let itemDownloader = NYPLAxisItemDownloader(
      assetWriter: assetWriter, downloader: contentDownloader,
      weightProvider: weightProvider)
    
    contentDownloader.mockDownloadSuccess()
    
    let progressListener = NYPLAxisProgressListenerMock()
    itemDownloader.delegate = progressListener
    XCTAssertEqual(progressListener.currentProgress, 0)
    
    
    itemDownloader.downloadItem(from: someURL, at: downloadsDirectory) { _ in }
    XCTAssertEqual(progressListener.currentProgress, 0.0)
  }
  
  func testDownloaderShouldUpdateDownloadProgressUponsWritingAsset() {
    let assetWriter = AssetWriterMock().mockingSuccess()
    
    let itemDownloader = NYPLAxisItemDownloader(
      assetWriter: assetWriter, downloader: contentDownloader,
      weightProvider: weightProvider)
    
    contentDownloader.mockDownloadSuccess()
    
    let progressListener = NYPLAxisProgressListenerMock()
    itemDownloader.delegate = progressListener
    XCTAssertEqual(progressListener.currentProgress, 0)
    
    itemDownloader.downloadItem(from: someURL, at: downloadsDirectory) { _ in }
    XCTAssertEqual(progressListener.currentProgress, 0.4)
    
    itemDownloader.downloadItem(from: someOtherURL, at: downloadsDirectory) { _ in }
    XCTAssertEqual(progressListener.currentProgress, 0.6)
  }
  
}
