//
//  NYPLPackageEndpointProviderTests.swift
//  OpenEbooksTests
//
//  Created by Raman Singh on 2021-05-18.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import XCTest
@testable import SimplyE

class NYPLPackageEndpointProviderTests: XCTestCase {
  
  private let keysProvider = NYPLAxisKeysProvider()
  private let validContainer = "container"
  private let invalidContainer = "containerInvalid"
  
  lazy private var downloadsDirectory: URL = {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory.appendingPathComponent("NYPLAxisLicenseServiceTests")
  }()
  
  lazy private var containerURL: URL = {
    return downloadsDirectory
      .appendingPathComponent(keysProvider.containerDownloadEndpoint)
  }()
  
  override func tearDown() {
    super.tearDown()
    try? FileManager.default.removeItem(at: containerURL)
  }
 
  func testPackageEndpointProviderShouldReturnNilIfNoContainerFound() {
    let endpointProvider = NYPLAxisPackageEndpointProvider(
      containerURL: containerURL, fullPathKey: keysProvider.fullPathKey)
    
    XCTAssertNil(endpointProvider.getPackageEndpoint())
  }
  
  func testPackageEndpointProviderShouldReturnNilIfContainerIsInvalid() {
    let endpointProvider = NYPLAxisPackageEndpointProvider(
      containerURL: containerURL, fullPathKey: keysProvider.fullPathKey)
    
    mockDownloadedContainer(invalidContainer)
    XCTAssertNil(endpointProvider.getPackageEndpoint())
  }
  
  func testPackageEndpointProviderShouldReturnContainerEndpointIfContainerIsValid() {
    let endpointProvider = NYPLAxisPackageEndpointProvider(
      containerURL: containerURL, fullPathKey: keysProvider.fullPathKey)
    
    mockDownloadedContainer(validContainer)
    
    XCTAssertEqual("ops/package.opf", endpointProvider.getPackageEndpoint())
  }
  
  func mockDownloadedContainer(_ fileName: String) {
    
    let itemURL = Bundle(for: NYPLPackageEndpointProviderTests.self)
      .url(forResource: fileName, withExtension: "xml")!
    let containerData = try! Data(contentsOf: itemURL)
    try! NYPLAssetWriter().writeAsset(containerData, atURL: containerURL)
  }
  
}
