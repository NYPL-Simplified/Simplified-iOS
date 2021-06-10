//
//  NYPLAxisLicenseServiceTests.swift
//  OpenEbooksTests
//
//  Created by Raman Singh on 2021-05-13.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//
import XCTest
@testable import SimplyE

class NYPLAxisLicenseServiceTests: XCTestCase {

  private let axisKeysProvider = NYPLAxisKeysProvider()
  private let itemDownloader = CustomNYPLAxisItemDownloader()
  private let progressListener = NYPLAxisProgressListenerMock()

  lazy var licenseHomeDirectory: URL = {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory.appendingPathComponent("NYPLAxisLicenseServiceTests")
  }()

  lazy private var downloadedLicenseURL: URL = {
    return licenseHomeDirectory
      .appendingPathComponent(self.axisKeysProvider.desiredNameForLicenseFile)
  }()

  lazy private var cypherReturningBook2VaultId: NYPLRSACryptographing = {
    return NYPLRSACypherMock { () -> String in
      TestBook.book2.bookVaultId
    } aesClosure: { nil }
  }()

  override func tearDown() {
    super.tearDown()
    try? FileManager.default.removeItem(at: self.licenseHomeDirectory)
  }

  func testLicenseWithInvalidKeycheckShouldNotBeValidated() {
    let failedValidationExpectation = XCTestExpectation(
      description: "Invalid license should not be validated")
    failedValidationExpectation.expectedFulfillmentCount = 2

    let service = createLicenseService(bookVaultId: TestBook.book1.bookVaultId,
                                       cypher: cypherReturningBook2VaultId,
                                       isbn: TestBook.book1.isbn)

    mockDownloadedLicense()
    XCTAssertTrue(FileManager.default.fileExists(atPath: downloadedLicenseURL.path))

    itemDownloader.downloadsTerminated = {
      failedValidationExpectation.fulfill()
    }

    service.didLogLicenseError = {
      if $0 == "AxisLicenseService validation failed due to invalid vault ID in license" {
        failedValidationExpectation.fulfill()
      }
    }
    service.validateLicense()

    wait(for: [failedValidationExpectation], timeout: 4)
  }

  func testLicenseWithValidKeycheckShouldBeValidated() {
    let validationExpectation = XCTestExpectation(
      description: "Valid license should be validated")

    let service = createLicenseService(bookVaultId: TestBook.book2.bookVaultId,
                                       cypher: cypherReturningBook2VaultId,
                                       isbn: TestBook.book2.isbn)

    mockDownloadedLicense()
    XCTAssertTrue(FileManager.default.fileExists(atPath: downloadedLicenseURL.path))

    service.validateLicense()
    itemDownloader.delegate = progressListener
    progressListener.allDownloadsFinished = {
      if self.itemDownloader.shouldContinue {
        validationExpectation.fulfill()
      }
    }
    
    itemDownloader.notifyUponCompletion(on: .global(qos: .utility))
    wait(for: [validationExpectation], timeout: 4)
  }

  func testLicenseShouldSaveBookInfoForLaterUse() {
    let savedInfoExpectation = XCTestExpectation(
      description: "Book info should be saved for later use")

    let service = createLicenseService(bookVaultId: TestBook.book1.bookVaultId,
                                       cypher: cypherReturningBook2VaultId,
                                       isbn: TestBook.book1.isbn)

    let designatedBookInfoURL = licenseHomeDirectory
      .appendingPathComponent(axisKeysProvider.bookFilePathKey)

    service.saveBookInfoForFetchingLicense()
    itemDownloader.delegate = progressListener
    progressListener.allDownloadsFinished = {
      if
        let data = try? Data(contentsOf: designatedBookInfoURL),
        let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed),
        let json = jsonObject as? [String: String],
        let bookVaultId = json[self.axisKeysProvider.bookVaultKey],
        bookVaultId == TestBook.book1.bookVaultId,
        let isbn = json[self.axisKeysProvider.isbnKey],
        isbn == TestBook.book1.isbn
      {
        savedInfoExpectation.fulfill()
      } else {
        XCTFail()
      }
    }
    
    
    itemDownloader.notifyUponCompletion(on: .global(qos: .utility))
    wait(for: [savedInfoExpectation], timeout: 4)
  }

  func testLicenseServiceShouldDeleteDownloadedLicense() {
    let deletionExpectation = XCTestExpectation(
      description: "License service should be able to delete license")

    let service = createLicenseService(bookVaultId: TestBook.book2.bookVaultId,
                                       cypher: cypherReturningBook2VaultId,
                                       isbn: TestBook.book2.isbn)

    mockDownloadedLicense()
    XCTAssertTrue(FileManager.default.fileExists(atPath: downloadedLicenseURL.path))

    service.deleteLicenseFile()
    itemDownloader.delegate = progressListener
    progressListener.allDownloadsFinished = {
      if !FileManager.default.fileExists(atPath: self.downloadedLicenseURL.path) {
        deletionExpectation.fulfill()
      }
    }
    
    itemDownloader.notifyUponCompletion(on: .global(qos: .utility))
    
    wait(for: [deletionExpectation], timeout: 4)
  }

  private func createLicenseService(bookVaultId: String,
                                    cypher: NYPLRSACryptographing,
                                    isbn: String) -> CustomNYPLAxisLicenseService {

    return CustomNYPLAxisLicenseService(
      axisItemDownloader: itemDownloader, bookVaultId: bookVaultId,
      cypher: cypher, isbn: isbn, parentDirectory: self.licenseHomeDirectory)
  }

  private func mockDownloadedLicense() {
    let dummyLicenseURL = Bundle(for: NYPLAxisLicenseServiceTests.self)
      .url(forResource: "license", withExtension: "json")!
    let licenseData = try! Data(contentsOf: dummyLicenseURL)
    try! NYPLAssetWriter().writeAsset(licenseData, atURL: downloadedLicenseURL)
  }

}

private struct TestBook {
  let isbn: String
  let bookVaultId: String

  static let book1 = TestBook(isbn: "9781619634015", bookVaultId: "23593B59-F4A2-4722-A3D3-4DF348037757")
  static let book2 = TestBook(isbn: "9781250109699", bookVaultId: "872D8384-7F33-4B2C-81A5-267415C0170B")
}


private class CustomNYPLAxisItemDownloader: NYPLAxisItemDownloader {

  var downloadsTerminated: (() -> Void)?

  override func terminateDownloadProcess() {
    downloadsTerminated?()
    super.terminateDownloadProcess()
  }
}

private class CustomNYPLAxisLicenseService: NYPLAxisLicenseService {

  var didLogLicenseError: ((String) -> ())?

  override func logLicenseErrorAndTerminateDownload(summary: String,
                                        reason: String,
                                        additionalInfo: [String: String] = [:]) {
    didLogLicenseError?(reason)
    super.logLicenseErrorAndTerminateDownload(
      summary: summary, reason: reason, additionalInfo: additionalInfo)
  }

}
