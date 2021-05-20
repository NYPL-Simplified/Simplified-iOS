//
//  NYPLAssetWriterTests.swift
//  OpenEbooksTests
//
//  Created by Raman Singh on 2021-05-18.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import XCTest
@testable import SimplyE

class NYPLAssetWriterTests: XCTestCase {
  
  lazy private var downloadsDirectory: URL = {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory.appendingPathComponent("NYPLAxisLicenseServiceTests")
  }()
  
  override func tearDown() {
    super.tearDown()
    try? FileManager.default.removeItem(at: self.downloadsDirectory)
  }
  
  func testAssetWriterShouldWriteAsset() {
    
    let data = "Some data".data(using: .utf8)!
    let endpath = Array(1...10).shuffled().reduce("") { return $0 + "/\($1)" }
    let fileName = "SomeFile.txt"
    
    let writeURL = downloadsDirectory
      .appendingPathComponent(endpath)
      .appendingPathComponent(fileName)
    
    let assetWriter = NYPLAssetWriter()
    try? assetWriter.writeAsset(data, atURL: writeURL)
    
    let fileExists = FileManager.default.fileExists(atPath: writeURL.path)
    
    XCTAssertTrue(fileExists)
  }
  
  func testAssetWriterShouldOverwritePreviouslyWrittenAsset() {
    
    let data = "Some data".data(using: .utf8)!
    let endpath = Array(1...10).shuffled().reduce("") { return $0 + "/\($1)" }
    let fileName = "SomeFile.txt"
    
    let writeURL = downloadsDirectory
      .appendingPathComponent(endpath)
      .appendingPathComponent(fileName)
    
    let assetWriter = NYPLAssetWriter()
    try? assetWriter.writeAsset(data, atURL: writeURL)
    
    let newData = "Some new data".data(using: .utf8)!
    try? assetWriter.writeAsset(newData, atURL: writeURL)
    
    let expected = newData
    let actual = try? Data(contentsOf: writeURL)
    
    XCTAssertEqual(expected, actual)
  }
  
}
