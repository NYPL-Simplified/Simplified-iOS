//
//  NYPLAxisMetadataServiceTests.swift
//  OpenEbooksTests
//
//  Created by Raman Singh on 2021-05-18.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//
import XCTest
@testable import SimplyE

class NYPLAxisMetadataServiceTests: XCTestCase {
  
  private let contentDownloader = NYPLAxisContentDownloaderMock()
  private let keysProvider = NYPLAxisKeysProvider()
  private let baseURL = URL(string: "www.mock.com")!
  private let assetWriter = AssetWriterMock()
  private let progressListener = NYPLAxisProgressListenerMock()
  
  lazy private var itemDownloader: NYPLAxisItemDownloader = {
    let downloader = NYPLAxisItemDownloader(
      assetWriter: assetWriter, downloader: contentDownloader)
    downloader.delegate = progressListener
    return downloader
  }()
  
  lazy private var downloadsDirectory: URL = {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory.appendingPathComponent("NYPLAxisLicenseServiceTests")
  }()
  
  lazy private var encryptionURL: URL = {
    return baseURL
      .appendingPathComponent(keysProvider.encryptionDownloadEndpoint)
  }()
  
  lazy private var containerURL: URL = {
    return baseURL
      .appendingPathComponent(keysProvider.containerDownloadEndpoint)
  }()
  
  lazy private var metadataService: NYPLAxisMetadataService = {
    return NYPLAxisMetadataService(
      axisItemDownloader: itemDownloader, axisKeysProvider: keysProvider,
      baseURL: baseURL, parentDirectory: downloadsDirectory)
  }()
  
  override func setUp() {
    super.setUp()
    itemDownloader.delegate = progressListener
  }
  
  func testMetadataServiceShouldNotContinueUponDownloadFailure() {
    let notifyExpecation = self.expectation(
      description: "Metadata service should notify listener upon failure")
    let encryptonFetchExpectation = self.expectation(
      description: "Metadata service should attempt to download encryption")
    
    contentDownloader.mockDownloadFailure()
    contentDownloader.didReceiveRequestForUrl = {
      if $0 == self.containerURL {
        XCTFail()
      }
      if $0 == self.encryptionURL {
        encryptonFetchExpectation.fulfill()
      }
    }
    
    progressListener.didTerminate = {
      notifyExpecation.fulfill()
    }
    
    metadataService.downloadContent()
    itemDownloader.notifyUponCompletion(on: .global(qos: .utility))
    
    waitForExpectations(timeout: 4, handler: nil)
  }
  
  func testMetadataServiceShouldNotContinueUponWriteFailure() {
    let leaveExpecation = self.expectation(
      description: "Metadata service should notify listener upon failure")
    let encryptonFetchExpectation = self.expectation(
      description: "Metadata service should attempt to download encryption")
    let writeAttemptExpecation = self.expectation(
      description: "Metadata service should attempt to write asset upon successful download")
    
    contentDownloader.mockDownloadSuccess()
    assetWriter.mockingFailure()
    contentDownloader.didReceiveRequestForUrl = {
      if $0 == self.containerURL {
        XCTFail()
      }
      if $0 == self.encryptionURL {
        encryptonFetchExpectation.fulfill()
      }
    }
    
    progressListener.didTerminate = {
      leaveExpecation.fulfill()
    }
    
    assetWriter.willWriteAsset = {
      writeAttemptExpecation.fulfill()
    }
    
    metadataService.downloadContent()
    itemDownloader.notifyUponCompletion(on: .global(qos: .utility))
    
    waitForExpectations(timeout: 4, handler: nil)
  }
  
  func testMetadataServiceShouldDownloadContainerUponEncryptionDownloadSuccess() {
    let encryptonFetchExpectation = self.expectation(
      description: "Metadata service should attempt to download encryption")
    let containerFetchExpecatation = self.expectation(
      description: "Metadata service should download container upon encryption download success")
    let notifyExpecation = self.expectation(
      description: "Metadata service should notify listener upon success")
    
    contentDownloader.mockDownloadSuccess()
    assetWriter.mockingSuccess()
    contentDownloader.didReceiveRequestForUrl = {
      if $0 == self.containerURL {
        containerFetchExpecatation.fulfill()
      }
      if $0 == self.encryptionURL {
        encryptonFetchExpectation.fulfill()
      }
    }
    
    metadataService.downloadContent()
    progressListener.allDownloadsFinished = {
      notifyExpecation.fulfill()
    }
    
    itemDownloader.notifyUponCompletion(on: .global(qos: .utility))
    
    waitForExpectations(timeout: 4, handler: nil)
  }
  
  
}
