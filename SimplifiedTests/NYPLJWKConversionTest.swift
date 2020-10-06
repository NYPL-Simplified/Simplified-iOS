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
  var expectedPublicKeyData: Data!

  override func setUp() {
    super.setUp()
    // Initialize test data
    let bundle = Bundle(for: NYPLJWKConversionTest.self)
    // JWK response data - data received from https://listen.cantookaudio.com/.well-known/jwks.json
    jwkResponseData = try! Data(contentsOf: bundle.url(forResource: "jwk", withExtension: "json")!)
    // Expected public key data - extracted from PEM file,
    // content between -----BEGIN PUBLIC KEY----- and -----END PUBLIC KEY-----
    let expectedPublicKeyString = try! String(contentsOf: bundle.url(forResource: "jwk_public", withExtension: nil)!)
    expectedPublicKeyData = Data(base64Encoded: expectedPublicKeyString.replacingOccurrences(of: "\n", with: ""))
  }

  override func tearDown() {
    super.tearDown()
    jwkResponseData = nil
    expectedPublicKeyData = nil
  }

  func testJWKConversion() throws {
    let jwkResponse = try? JSONDecoder().decode(JWKResponse.self, from: jwkResponseData)
    XCTAssertNotNil(jwkResponse)
    let jwk = jwkResponse?.keys.first
    XCTAssertNotNil(jwk)
    let publicKeyData = jwk?.publicKeyData
    XCTAssertNotNil(publicKeyData)
    XCTAssertEqual(publicKeyData!, expectedPublicKeyData)
  }

}
