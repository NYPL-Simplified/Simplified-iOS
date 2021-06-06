//
//  NYPLZlibDecompressorTests.swift
//  OpenEbooksTests
//
//  Created by Raman Singh on 2021-05-28.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import XCTest
@testable import SimplyE

/// Note: The compressed and decompressed files used in the tests were created locally and do not contain
/// any information that one would obtain from a real book
class NYPLZlibDecompressorTests: XCTestCase {
  
  lazy private var preloadedDecompressedFileData: Data = {
    let preloadedDecompressedFile = Bundle(for: NYPLZlibDecompressorTests.self)
      .url(forResource: "DummyDecompressedFile", withExtension: "html")!
    return try! Data(contentsOf: preloadedDecompressedFile)
  }()
  
  lazy private var expectedValue: String = {
    return String(data: preloadedDecompressedFileData, encoding: .utf8)!
  }()
  
  lazy private var compressedData: Data = {
    let compressedFileURL = Bundle(for: NYPLZlibDecompressorTests.self)
      .url(forResource: "DummyCompressedFile", withExtension: "html")!
    return try! Data(contentsOf: compressedFileURL)
  }()
  
  @available(iOS 13.0, *)
  func testDecompressingCompressedFileWithNewAlogrithm() {
    let decompressedData = NYPLZlibDecompressor().decompressWithNewAlgorithm(compressedData)!
    let actual = String(data: decompressedData, encoding: .utf8)
    
    XCTAssertEqual(decompressedData, preloadedDecompressedFileData)
    XCTAssertEqual(actual, expectedValue)
  }
  
  func testDecompressingCompressedFileWithOldAlgorithm() {
    let decompressedData = NYPLZlibDecompressor().decompressInChunks(compressedData)!
    let actual = String(data: decompressedData, encoding: .utf8)
    
    XCTAssertEqual(decompressedData, preloadedDecompressedFileData)
    XCTAssertEqual(actual, expectedValue)
  }

}
