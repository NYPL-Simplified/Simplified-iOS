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
  private let progressListener = NYPLAxisProgressListenerMock()
  
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
    let notifyExpecation = self.expectation(
      description: "Downloader should notify listener on failed download")
    
    let itemDownloader = NYPLAxisItemDownloader(downloader: contentDownloader)
    contentDownloader.mockDownloadFailure()
    
    contentDownloader.didReceiveRequestForUrl = {
      if $0 == self.someOtherURL {
        XCTFail()
      }
    }
    
    itemDownloader.delegate = progressListener
    progressListener.didTerminate = {
      notifyExpecation.fulfill()
    }
    itemDownloader.downloadItem(from: someURL, at: downloadsDirectory)
    itemDownloader.notifyUponCompletion(on: .global(qos: .utility))
    
    if !itemDownloader.shouldContinue {
      stopExpectation.fulfill()
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
    itemDownloader.downloadItem(from: someURL, at: downloadsDirectory)
    
    waitForExpectations(timeout: 4, handler: nil)
  }
  
  func testDownloaderShouldWriteAssetUponSuccessfulDownload() {
    let writeExpectation = self.expectation(
      description: "Downloader should write asset upon successful download")
    let notifyExpectation = self.expectation(
      description: "Downloader should notify listener upon successful downloads")
    
    writeExpectation.expectedFulfillmentCount = 2
    
    let assetWriter = AssetWriterMock().mockingSuccess()
    assetWriter.willWriteAsset = {
      writeExpectation.fulfill()
    }
    
    let itemDownloader = NYPLAxisItemDownloader(
      assetWriter: assetWriter, downloader: contentDownloader)
    contentDownloader.mockDownloadSuccess()
    
    itemDownloader.delegate = progressListener
    progressListener.allDownloadsFinished = {
      notifyExpectation.fulfill()
    }
    
    itemDownloader.downloadItems(with: [someURL: downloadsDirectory,
                                        someOtherURL: downloadsDirectory])
    
    itemDownloader.notifyUponCompletion(on: .global())
    
    waitForExpectations(timeout: 4, handler: nil)
  }
  
  func testDownloaderShouldNotContinueUponAssetWriteFailure() {
    let stopExpectation = self.expectation(
      description: "Downloader should not continue after failure writing asset")
    let notifyExpectation = self.expectation(
      description: "Downloader should notify listener on asset write failure")
    
    let assetWriter = AssetWriterMock().mockingFailure()
    
    let itemDownloader = NYPLAxisItemDownloader(
      assetWriter: assetWriter, downloader: contentDownloader)
    contentDownloader.mockDownloadSuccess()
    
    contentDownloader.didReceiveRequestForUrl = {
      if $0 == self.someOtherURL {
        XCTFail()
      }
    }
    
    itemDownloader.delegate = progressListener
    progressListener.didTerminate = {
      notifyExpectation.fulfill()
    }
    
    itemDownloader.downloadItem(from: someURL, at: downloadsDirectory)
    itemDownloader.notifyUponCompletion(on: .global(qos: .utility))
    
    if !itemDownloader.shouldContinue {
      stopExpectation.fulfill()
    }
    
    itemDownloader.downloadItem(from: someOtherURL, at: downloadsDirectory)
    
    waitForExpectations(timeout: 4, handler: nil)
  }
  
  func testDownloaderShouldContinueUponSuccessfulDownload() {
    let notifyExpectation = self.expectation(
      description: "Downloader should notify listener upon successful downloads")
    let requestExpectation = self.expectation(
      description: "Downloader should be able to make subsequent requests after success")
    let continueExpecation = self.expectation(
      description: "Downloader should continue if no failure occurs")
    
    [requestExpectation, continueExpecation].forEach {
      $0.expectedFulfillmentCount = 2
    }
    
    let assetWriter = AssetWriterMock().mockingSuccess()
    let itemDownloader = NYPLAxisItemDownloader(
      assetWriter: assetWriter,
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
    
    itemDownloader.delegate = progressListener
    
    progressListener.allDownloadsFinished = {
      notifyExpectation.fulfill()
    }
    
    itemDownloader.downloadItem(from: someURL, at: downloadsDirectory)
    if itemDownloader.shouldContinue {
      continueExpecation.fulfill()
    }
    
    itemDownloader.downloadItem(from: someOtherURL, at: downloadsDirectory)
    if itemDownloader.shouldContinue {
      continueExpecation.fulfill()
    }
    
    itemDownloader.notifyUponCompletion(on: .global())
    
    waitForExpectations(timeout: 4, handler: nil)
  }
  
  func testDownloaderShouldNotUpdateProgressUponFailureDownloadingAsset() {
    let assetWriter = AssetWriterMock().mockingSuccess()
    
    let itemDownloader = NYPLAxisItemDownloader(
      assetWriter: assetWriter,
      downloader: contentDownloader, weightProvider: weightProvider)
    
    let progressListener = NYPLAxisProgressListenerMock()
    itemDownloader.delegate = progressListener
    XCTAssertEqual(progressListener.currentProgress, 0)
    
    contentDownloader.mockDownloadSuccess()
    itemDownloader.downloadItem(from: someURL, at: downloadsDirectory)
    XCTAssertEqual(progressListener.currentProgress, 0.4)
    
    contentDownloader.mockDownloadFailure()
    itemDownloader.downloadItem(from: someOtherURL, at: downloadsDirectory)
    XCTAssertEqual(progressListener.currentProgress, 0.4)
  }
  
  func testDownloaderShouldNotUpdateProgressUponFailureWritingAsset() {
    let assetWriter = AssetWriterMock().mockingFailure()
    
    let itemDownloader = NYPLAxisItemDownloader(
      assetWriter: assetWriter,
      downloader: contentDownloader, weightProvider: weightProvider)
    
    contentDownloader.mockDownloadSuccess()
    
    let progressListener = NYPLAxisProgressListenerMock()
    itemDownloader.delegate = progressListener
    XCTAssertEqual(progressListener.currentProgress, 0)
    
    itemDownloader.downloadItem(from: someURL, at: downloadsDirectory)
    XCTAssertEqual(progressListener.currentProgress, 0.0)
  }
  
  func testDownloaderShouldUpdateDownloadProgressUponsWritingAsset() {
    
    let assetWriter = AssetWriterMock().mockingSuccess()
    let itemDownloader = NYPLAxisItemDownloader(
      assetWriter: assetWriter,
      downloader: contentDownloader, weightProvider: weightProvider)
    
    contentDownloader.mockDownloadSuccess()
    
    let progressListener = NYPLAxisProgressListenerMock()
    itemDownloader.delegate = progressListener
    XCTAssertEqual(progressListener.currentProgress, 0)
    
    itemDownloader.downloadItem(from: someURL, at: downloadsDirectory)
    XCTAssertEqual(progressListener.currentProgress, 0.4)
    
    itemDownloader.downloadItem(from: someOtherURL, at: downloadsDirectory)
    XCTAssertEqual(progressListener.currentProgress, 0.6)
  }
  
}
