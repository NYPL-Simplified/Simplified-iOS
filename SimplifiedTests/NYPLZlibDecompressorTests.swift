//
//  NYPLZlibDecompressorTests.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-05-13.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
import XCTest
@testable import SimplyE

class NYPLZlibDecompressorTests: XCTestCase {
  
  func testDecompressingCompressedFile() {
    let compressedFileURL = Bundle(for: NYPLZlibDecompressorTests.self)
      .url(forResource: "ch07Compressed", withExtension: "html")!
    let compressedData = try! Data(contentsOf: compressedFileURL)
    
    let decompressedFileURL = Bundle(for: NYPLZlibDecompressorTests.self)
      .url(forResource: "ch07Decompressed", withExtension: "html")!
    let expectedResult = try! Data(contentsOf: decompressedFileURL)
    
    let actualResult = NYPLZlibDecompressor().decompress(sourceData: compressedData)
    
    XCTAssertEqual(expectedResult, actualResult)
  }

}
