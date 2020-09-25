//
//  NYPLJWKConversionTest.swift
//  SimplyETests
//
//  Created by Vladimir Fedorov on 31.08.2020.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import XCTest
@testable import SimplyE

class NYPLJWKConversionTest: XCTestCase {
  
  var jwkResponseData: Data!
  var expectedPrivateKeyData: Data!
  var expectedPublicKeyData: Data!

  override func setUp() {
    super.setUp()
    // Initialize test data
    let bundle = Bundle(for: NYPLJWKConversionTest.self)
    // JWK response data - data received from https://listen.cantookaudio.com/.well-known/jwks.json
    jwkResponseData = try! Data(contentsOf: bundle.url(forResource: "jwk", withExtension: "json")!)
    // Expected private key data - extracted from PEM file,
    // content between -----BEGIN RSA PRIVATE KEY----- and -----END RSA PRIVATE KEY-----
    let expectedPrivateKeyString = try! String(contentsOf: bundle.url(forResource: "jwk_private", withExtension: nil)!)
    expectedPrivateKeyData = expectedPrivateKeyString.replacingOccurrences(of: "\n", with: "").data(using: .utf8, allowLossyConversion: false)?.base64EncodedData()
  }

  override func tearDown() {
    super.tearDown()
    jwkResponseData = nil
    expectedPublicKeyData = nil
    expectedPrivateKeyData = nil
  }

  // TODO: SIMPLY-3131
//  func testJWKConversion() throws {
//    let jwkResponse = try? JSONDecoder().decode(JWKResponse.self, from: jwkResponseData)
//    XCTAssertNotNil(jwkResponse)
//    let jwk = jwkResponse?.keys.first
//    XCTAssertNotNil(jwk)
//    let publicKey = jwk?.publicKeyData
//    XCTAssertNotNil(publicKey)
//    XCTAssertEqual(publicKey!, expectedPrivateKeyData)
//  }

}
