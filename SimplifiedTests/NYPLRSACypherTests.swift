//
//  NYPLRSACypherTests.swift
//  OpenEbooksTests
//
//  Created by Raman Singh on 2021-05-13.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
import XCTest
@testable import SimplyE

class NYPLRSACypherTests: XCTestCase {
  
 let cypher = NYPLRSACypher()!
  
  func testCypherShouldDecryptDataWithAESKey() {
    let decryptedAESKeyURL = Bundle(for: NYPLRSACypherTests.self)
      .url(forResource: "AESKeyData", withExtension: "txt")!
    let decryptedAESKeyData = try! Data(contentsOf: decryptedAESKeyURL)
    
    let encryptedFileURL = Bundle(for: NYPLZlibDecompressorTests.self)
      .url(forResource: "ch07Encrypted", withExtension: "html")!
    let encryptedFileData = try! Data(contentsOf: encryptedFileURL)
    
    let comparisionFileURL = Bundle(for: NYPLZlibDecompressorTests.self)
      .url(forResource: "ch07Compressed", withExtension: "html")!
    let comparisionCompressedData = try! Data(contentsOf: comparisionFileURL)
    let expectedDecompressedData = NYPLZlibDecompressor().decompress(sourceData: comparisionCompressedData)
    
    let decrypted = cypher.decryptWithAES(encryptedFileData, key: decryptedAESKeyData)!
    let actualDecompressedData = NYPLZlibDecompressor().decompress(sourceData: decrypted)
    
    
    XCTAssertEqual(expectedDecompressedData, actualDecompressedData)
  }
  
}
