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

  lazy private var itemDownloader: NYPLAxisItemDownloader = {
    return NYPLAxisItemDownloader(
      assetWriter: assetWriter, downloader: contentDownloader)
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


  func testMetadataServiceShouldDownloadContainerUponEncryptionDownloadSuccess() {
    let containerRequestExpectation = self.expectation(
      description: "Metadata service should download container upon encryption download success")
    let encryptonDownloadExpectation = self.expectation(
      description: "Metadata service should attempt to download encryption.xml")

    contentDownloader.mockDownloadSuccess()
    assetWriter.mockingSuccess()
    contentDownloader.didReceiveRequestForUrl = {
      if $0 == self.containerURL {
        containerRequestExpectation.fulfill()
      }
      if $0 == self.encryptionURL {
        encryptonDownloadExpectation.fulfill()
      }
    }
    
    let aggregator = NYPLAxisTaskAggregator()
    aggregator
      .addTasks(metadataService.downloadMetadataTasks())
      .run()
      .onCompletion { _ in }

    waitForExpectations(timeout: 4, handler: nil)
  }
  
  func testMetadataServiceShouldNotDownloadContainerUponEncryptionDownloadFailure() {
    let containerRequestExpectation = self.expectation(
      description: "Metadata service should not download container upon encryption download failure")
    let encryptonDownloadExpectation = self.expectation(
      description: "Metadata service should attempt to download encryption.xml")
    
    containerRequestExpectation.isInverted = true

    contentDownloader.mockDownloadFailure()
    assetWriter.mockingSuccess()
    contentDownloader.didReceiveRequestForUrl = {
      if $0 == self.containerURL {
        containerRequestExpectation.fulfill()
      }
      if $0 == self.encryptionURL {
        encryptonDownloadExpectation.fulfill()
      }
    }
    
    let aggregator = NYPLAxisTaskAggregator()
    aggregator
      .addTasks(metadataService.downloadMetadataTasks())
      .run()
      .onCompletion { _ in }

    waitForExpectations(timeout: 4, handler: nil)
  }

  
}
