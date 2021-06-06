//
//  NYPLRSACypherTests.swift
//  OpenEbooksTests
//
//  Created by Raman Singh on 2021-05-28.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import XCTest
@testable import SimplyE

class NYPLRSACypherTests: XCTestCase {
  
 var cypher = NYPLRSACypher()
  
  override func tearDown() {
    super.tearDown()
    cypher = nil
  }
  
  override func setUpWithError() throws {
    try super.setUpWithError()
    cypher = NYPLRSACypher()
  }
  
  /// Note: The user key, encrypted file, and decrypted file used in the test were created locally and do not
  /// contain any information that one would obtain from a real book
  func testCypherShouldDecryptDataWithAESKey() throws {
    let aesKeyURL = Bundle(for: NYPLRSACypherTests.self)
      .url(forResource: "userKey", withExtension: nil)!
    let aesKeyData = try Data(contentsOf: aesKeyURL)
    
    let encryptedFileURL = Bundle(for: NYPLRSACypherTests.self)
      .url(forResource: "encrypted", withExtension: "txt")!
    let encryptedFileData = try Data(contentsOf: encryptedFileURL)
    
    let decryptedFileURL = Bundle(for: NYPLRSACypherTests.self)
      .url(forResource: "decrypted", withExtension: "txt")!
    
    let expectedDecryptedData = try Data(contentsOf: decryptedFileURL)
    let actualDecryptedData = cypher?
      .decryptWithAES(encryptedFileData, key: aesKeyData)
    
    XCTAssertEqual(expectedDecryptedData, actualDecryptedData)
  }
  
}
