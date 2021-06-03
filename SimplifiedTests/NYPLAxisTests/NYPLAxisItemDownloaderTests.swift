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
  
  func testDownloaderShouldNotContinueOnFailedDownload() {
    let stopExpectation = self.expectation(
      description: "Downloader should not continue after download failure")
    let leaveExpecation = self.expectation(
      description: "Downloader should leave dispatch group on failed download")
    
    leaveExpecation.expectedFulfillmentCount = 2
    
    let dispatchGroup = DispatchGroup()
    let itemDownloader = NYPLAxisItemDownloader(
      dispatchGroup: dispatchGroup, downloader: contentDownloader)
    contentDownloader.mockDownloadFailure()
    
    contentDownloader.didReceiveRequestForUrl = {
      if $0 == self.someOtherURL {
        XCTFail()
      }
    }
    
    dispatchGroup.enter()
    itemDownloader.downloadItem(from: someURL, at: downloadsDirectory)
    
    dispatchGroup.notify(queue: .global()) {
      leaveExpecation.fulfill()
    }
    
    if !itemDownloader.shouldContinue {
      stopExpectation.fulfill()
    }
    
    dispatchGroup.enter()
    itemDownloader.downloadItem(from: someOtherURL, at: downloadsDirectory)
    dispatchGroup.notify(queue: .global()) {
      leaveExpecation.fulfill()
    }
    
    waitForExpectations(timeout: 4, handler: nil)
  }
  
  func testDownloaderShouldNotifyDelegateUponFailure() {
    let notifyExpectation = self.expectation(
      description: "Downloader should notify listener about failure")
    
    let progressListener = NYPLAxisProgressListenerMock()
    progressListener.didTerminate = {
      notifyExpectation.fulfill()
    }
    
    let itemDownloader = NYPLAxisItemDownloader(downloader: contentDownloader)
    
    itemDownloader.delegate = progressListener
    contentDownloader.mockDownloadFailure()
    
    itemDownloader.dispatchGroup.enter()
    itemDownloader.downloadItem(from: someURL, at: downloadsDirectory)
    
    waitForExpectations(timeout: 4, handler: nil)
  }
  
  func testDownloaderShouldWriteAssetUponSuccessfulDownload() {
    let writeExpectation = self.expectation(
      description: "Downloader should write asset upon successful download")
    let leaveExpecation = self.expectation(
      description: "Downloader should leave dispatch group on successful download")
    
    let dispatchGroup = DispatchGroup()
    
    let assetWriter = AssetWriterMock().mockingSuccess()
    assetWriter.willWriteAsset = {
      writeExpectation.fulfill()
    }
    
    let itemDownloader = NYPLAxisItemDownloader(
      assetWriter: assetWriter, dispatchGroup: dispatchGroup,
      downloader: contentDownloader)
    contentDownloader.mockDownloadSuccess()
    
    dispatchGroup.enter()
    itemDownloader.downloadItem(from: someURL, at: downloadsDirectory)
    
    dispatchGroup.notify(queue: .global()) {
      leaveExpecation.fulfill()
    }
    
    waitForExpectations(timeout: 4, handler: nil)
  }
  
  func testDownloaderShouldNotContinueUponAssetWriteFailure() {
    let stopExpectation = self.expectation(
      description: "Downloader should not continue after failure writing asset")
    let leaveExpecation = self.expectation(
      description: "Downloader should leave dispatch group on asset write failure")
    
    leaveExpecation.expectedFulfillmentCount = 2
    
    let dispatchGroup = DispatchGroup()
    let assetWriter = AssetWriterMock().mockingFailure()
    
    let itemDownloader = NYPLAxisItemDownloader(
      assetWriter: assetWriter, dispatchGroup: dispatchGroup,
      downloader: contentDownloader)
    contentDownloader.mockDownloadSuccess()
    
    contentDownloader.didReceiveRequestForUrl = {
      if $0 == self.someOtherURL {
        XCTFail()
      }
    }
    
    dispatchGroup.enter()
    itemDownloader.downloadItem(from: someURL, at: downloadsDirectory)
    dispatchGroup.notify(queue: .global()) {
      leaveExpecation.fulfill()
    }
    
    if !itemDownloader.shouldContinue {
      stopExpectation.fulfill()
    }
    
    dispatchGroup.enter()
    itemDownloader.downloadItem(from: someOtherURL, at: downloadsDirectory)
    dispatchGroup.notify(queue: .global()) {
      leaveExpecation.fulfill()
    }
    
    waitForExpectations(timeout: 4, handler: nil)
  }
  
  func testDownloaderShouldContinueUponSuccessfulDownload() {
    let leaveExpecation = self.expectation(
      description: "Downloader should leave dispatch group upon successful download")
    let requestExpectation = self.expectation(
      description: "Downloader should be able to make subsequent requests after success")
    let continueExpecation = self.expectation(
      description: "Downloader should continue if no failure occurs")
    
    [requestExpectation, leaveExpecation, continueExpecation].forEach {
      $0.expectedFulfillmentCount = 2
    }
    
    let dispatchGroup = DispatchGroup()
    let assetWriter = AssetWriterMock().mockingSuccess()
    let itemDownloader = NYPLAxisItemDownloader(
      assetWriter: assetWriter, dispatchGroup: dispatchGroup,
      downloader: contentDownloader)
    contentDownloader.mockDownloadSuccess()
    
    contentDownloader.didReceiveRequestForUrl = {
      if $0 == self.someURL {
        requestExpectation.fulfill()
      }
      if $0 == self.someOtherURL {
        requestExpectation.fulfill()
      }
    }
    
    dispatchGroup.enter()
    itemDownloader.downloadItem(from: someURL, at: downloadsDirectory)
    dispatchGroup.notify(queue: .global()) {
      leaveExpecation.fulfill()
    }
    if itemDownloader.shouldContinue {
      continueExpecation.fulfill()
    }
    
    dispatchGroup.wait()
    dispatchGroup.enter()
    itemDownloader.downloadItem(from: someOtherURL, at: downloadsDirectory)
    dispatchGroup.notify(queue: .global()) {
      leaveExpecation.fulfill()
    }
    if itemDownloader.shouldContinue {
      continueExpecation.fulfill()
    }
    
    waitForExpectations(timeout: 4, handler: nil)
  }
  
  func testDownloaderShouldNotUpdateProgressUponFailureDownloadingAsset() {
    let dispatchGroup = DispatchGroup()
    let assetWriter = AssetWriterMock().mockingSuccess()
    
    let itemDownloader = NYPLAxisItemDownloader(
      assetWriter: assetWriter, dispatchGroup: dispatchGroup,
      downloader: contentDownloader, weightProvider: weightProvider)
    
    let progressListener = NYPLAxisProgressListenerMock()
    itemDownloader.delegate = progressListener
    XCTAssertEqual(progressListener.currentProgress, 0)
    
    dispatchGroup.enter()
    contentDownloader.mockDownloadSuccess()
    itemDownloader.downloadItem(from: someURL, at: downloadsDirectory)
    XCTAssertEqual(progressListener.currentProgress, 0.4)
    
    dispatchGroup.wait()
    dispatchGroup.enter()
    contentDownloader.mockDownloadFailure()
    itemDownloader.downloadItem(from: someOtherURL, at: downloadsDirectory)
    XCTAssertEqual(progressListener.currentProgress, 0.4)
  }
  
  func testDownloaderShouldNotUpdateProgressUponFailureWritingAsset() {
    let dispatchGroup = DispatchGroup()
    let assetWriter = AssetWriterMock().mockingFailure()
    
    let itemDownloader = NYPLAxisItemDownloader(
      assetWriter: assetWriter, dispatchGroup: dispatchGroup,
      downloader: contentDownloader, weightProvider: weightProvider)
    
    contentDownloader.mockDownloadSuccess()
    
    let progressListener = NYPLAxisProgressListenerMock()
    itemDownloader.delegate = progressListener
    XCTAssertEqual(progressListener.currentProgress, 0)
    
    dispatchGroup.enter()
    itemDownloader.downloadItem(from: someURL, at: downloadsDirectory)
    XCTAssertEqual(progressListener.currentProgress, 0.0)
  }
  
  func testDownloaderShouldUpdateDownloadProgressUponsWritingAsset() {
    let dispatchGroup = DispatchGroup()
    let assetWriter = AssetWriterMock().mockingSuccess()
    
    let itemDownloader = NYPLAxisItemDownloader(
      assetWriter: assetWriter, dispatchGroup: dispatchGroup,
      downloader: contentDownloader, weightProvider: weightProvider)
    
    contentDownloader.mockDownloadSuccess()
    
    let progressListener = NYPLAxisProgressListenerMock()
    itemDownloader.delegate = progressListener
    XCTAssertEqual(progressListener.currentProgress, 0)
    
    dispatchGroup.enter()
    itemDownloader.downloadItem(from: someURL, at: downloadsDirectory)
    XCTAssertEqual(progressListener.currentProgress, 0.4)
    
    dispatchGroup.wait()
    dispatchGroup.enter()
    itemDownloader.downloadItem(from: someOtherURL, at: downloadsDirectory)
    XCTAssertEqual(progressListener.currentProgress, 0.6)
  }
  
}
