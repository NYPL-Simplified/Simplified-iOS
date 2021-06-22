//
//  NYPLAxisServiceTests.swift
//  OpenEbooksTests
//
//  Created by Raman Singh on 2021-05-14.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import XCTest
@testable import SimplyE

class NYPLAxisServiceTests: XCTestCase {
  
  lazy private var downloadsDirectory: URL = {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory.appendingPathComponent("NYPLAxisLicenseServiceTests")
  }()
  
  lazy private var book: NYPLBook = {
    let acquisitions = [NYPLFake.genericAcquisition.dictionaryRepresentation()]
    
    return NYPLBook(dictionary: ["acquisitions": acquisitions,
                                 "categories" : ["Fantasy"],
                                 "id": "666",
                                 "title": "The Lord of the Rings",
                                 "updated": "2020-09-08T09:22:45Z"
    ])!
  }()
  
  private let itemDownloader = NYPLAxisItemDownloader()
  private let downloadBroadcaster = NYPLAxisBookDownloadBroadcasterMock()
  
  func testAxisServiceShouldFailUponLicenseDownloadFailure() {
    let downloadFailedExpectation = self.expectation(
      description: "Failed license process should result in failed download!")
      
    let axisService = createAxisService(licenseService: failingLicenseService,
                                        metadataService: succeedingMetadataService,
                                        packageService: succeedingPackageService)
    
    let task = URLSessionDownloadTask()
    
    downloadBroadcaster.downloadFailed = {
      downloadFailedExpectation.fulfill()
    }
    
    downloadBroadcaster.downloadSuccessful = {
      XCTFail()
    }
    
    axisService.fulfillAxisLicense(downloadTask: task)
    
    waitForExpectations(timeout: 4, handler: nil)
  }
  
  func testAxisServiceShouldFailUponMetadataContentDownloadFailure() {
    let downloadFailedExpectation = self.expectation(
      description: "Failed metadata download should result in failed download!")
      
    let axisService = createAxisService(licenseService: succeedingLicenseService,
                                        metadataService: failingMetadataService,
                                        packageService: succeedingPackageService)
    
    let task = URLSessionDownloadTask()
    
    downloadBroadcaster.downloadFailed = {
      downloadFailedExpectation.fulfill()
    }
    
    downloadBroadcaster.downloadSuccessful = {
      XCTFail()
    }
    
    axisService.fulfillAxisLicense(downloadTask: task)
    
    waitForExpectations(timeout: 4, handler: nil)
  }
  
  func testAxisServiceShouldFailUponPackageDownloadFailure() {
    let downloadFailedExpectation = self.expectation(
      description: "Failed package content download should result in failed download!")
    
    let axisService = createAxisService(licenseService: succeedingLicenseService,
                                        metadataService: succeedingMetadataService,
                                        packageService: failingPackageService)
    
    let task = URLSessionDownloadTask()
    
    downloadBroadcaster.downloadFailed = {
      downloadFailedExpectation.fulfill()
    }
    
    downloadBroadcaster.downloadSuccessful = {
      XCTFail()
    }
    
    axisService.fulfillAxisLicense(downloadTask: task)
    
    waitForExpectations(timeout: 4, handler: nil)
  }
  
  func testAxisServiceShouldSucceedWhenAllItemsAreDownloaded() {
    let downloadSucceededExpectation = self.expectation(
      description: "Axis Service should succeed upon successful download of all content")
    
    let axisService = createAxisService(licenseService: succeedingLicenseService,
                                        metadataService: succeedingMetadataService,
                                        packageService: succeedingPackageService)
    
    let task = URLSessionDownloadTask()
    
    downloadBroadcaster.downloadSuccessful = {
      downloadSucceededExpectation.fulfill()
    }
    
    downloadBroadcaster.downloadFailed = {
      XCTFail()
    }
    
    axisService.fulfillAxisLicense(downloadTask: task)
    
    waitForExpectations(timeout: 4, handler: nil)
  }
  
  private func createAxisService(
    licenseService: NYPLAxisLicenseServiceMock,
    metadataService: NYPLAxisMetadataServiceMock,
    packageService: NYPLAxisPackageServiceMock) -> NYPLAxisService {
    
    return NYPLAxisService(
      axisItemDownloader: itemDownloader, book: book,
      dedicatedWriteURL: downloadsDirectory, delegate: downloadBroadcaster,
      licenseService: licenseService, metadataDownloader: metadataService,
      packageDownloader: packageService)
  }
  
  private var succeedingLicenseService: NYPLAxisLicenseServiceMock {
    return NYPLAxisLicenseServiceMock(shouldSucceed: true, aesKeyData: nil)
  }
  
  private var failingLicenseService: NYPLAxisLicenseServiceMock {
    return NYPLAxisLicenseServiceMock(shouldSucceed: false, aesKeyData: nil)
  }
  
  private var succeedingMetadataService: NYPLAxisMetadataServiceMock {
    return NYPLAxisMetadataServiceMock(shouldSucceed: true)
  }
  
  private var failingMetadataService: NYPLAxisMetadataServiceMock {
    return NYPLAxisMetadataServiceMock(shouldSucceed: false)
  }
  
  private var succeedingPackageService: NYPLAxisPackageServiceMock {
    return NYPLAxisPackageServiceMock(shouldSucceed: true)
  }
  
  private var failingPackageService: NYPLAxisPackageServiceMock {
    return NYPLAxisPackageServiceMock(shouldSucceed: false)
  }
  
}
