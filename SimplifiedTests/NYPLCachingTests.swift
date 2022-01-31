//
//  NYPLCachingTests.swift
//  SimplyETests
//
//  Created by Ettore Pasquini on 3/25/20.
//  Copyright © 2020 NYPL. All rights reserved.
//

import XCTest
@testable import SimplyE

class NYPLCachingTests: XCTestCase {
  var libraryCallResponse: HTTPURLResponse!
  var sufficientHeadersResponse: HTTPURLResponse!
  var missingMaxAgeResponse: HTTPURLResponse!

  override func setUp() {
    libraryCallResponse = HTTPURLResponse(
      url: URL(string: "https://example.com/test")!,
      statusCode: 200,
      httpVersion: "HTTP/1.1",
      headerFields: [
        "Cache-Control" : "public, no-transform, max-age: 43200, s-maxage: 21600"
    ])!

    let expiresDate = Date().addingTimeInterval(43200)
    sufficientHeadersResponse = HTTPURLResponse(
      url: URL(string: "https://example.com/test")!,
      statusCode: 200,
      httpVersion: "HTTP/1.1",
      headerFields: [
        "cache-control" : "public, no-transform, max-age: 43200, s-maxage: 21600",
        "Expires": expiresDate.rfc1123String
    ])!

    missingMaxAgeResponse = HTTPURLResponse(
      url: URL(string: "https://example.com/test")!,
      statusCode: 200,
      httpVersion: "HTTP/1.1",
      headerFields: [
        "CACHE-CONTROL" : "public; s-max-age=666",
    ])
  }

  override func tearDown() {
    libraryCallResponse = nil
    sufficientHeadersResponse = nil
    missingMaxAgeResponse = nil
  }

  func testSufficientCacheHeaders() {
    XCTAssertFalse(libraryCallResponse.hasSufficientCachingHeaders)
    XCTAssertFalse(missingMaxAgeResponse.hasSufficientCachingHeaders)
    XCTAssertTrue(sufficientHeadersResponse.hasSufficientCachingHeaders)

    let sufficientHeadersResponse2 = HTTPURLResponse(
      url: URL(string: "https://example.com/test")!,
      statusCode: 200,
      httpVersion: "HTTP/1.1",
      headerFields: [
        "EXPIRES" : Date().rfc1123String,
        "etag": "23bad3"
    ])!
    XCTAssertTrue(sufficientHeadersResponse2.hasSufficientCachingHeaders)

    let sufficientHeadersResponse3 = HTTPURLResponse(
      url: URL(string: "https://example.com/test")!,
      statusCode: 200,
      httpVersion: "HTTP/1.1",
      headerFields: [
        "Last-Modified" : Date().rfc1123String,
        "etag": "23bad3"
    ])!
    XCTAssertTrue(sufficientHeadersResponse3.hasSufficientCachingHeaders)

    let insufficientHeadersResponse = HTTPURLResponse(
      url: URL(string: "https://example.com/test")!,
      statusCode: 200,
      httpVersion: "HTTP/1.1",
      headerFields: [
        "Expires" : Date().rfc1123String,
    ])!
    XCTAssertFalse(insufficientHeadersResponse.hasSufficientCachingHeaders)
  }

  func testMaxAgeExtraction() {
    XCTAssertEqual(libraryCallResponse.cacheControlMaxAge, 43200)
    XCTAssertNil(missingMaxAgeResponse?.cacheControlMaxAge)

    let differentCapitalizationResponse = HTTPURLResponse(
      url: URL(string: "https://example.com/test")!,
      statusCode: 200,
      httpVersion: "HTTP/1.1",
      headerFields: [
        "CACHE-CONTROL" : " mAx-Age=666",
    ])
    XCTAssertEqual(differentCapitalizationResponse?.cacheControlMaxAge, 666)

    let malformedResponse = HTTPURLResponse(
      url: URL(string: "https://example.com/test")!,
      statusCode: 200,
      httpVersion: "HTTP/1.1",
      headerFields: [
        "cache-control" : " max-age=",
    ])
    XCTAssertNil(malformedResponse?.cacheControlMaxAge)

    let malformedNumberResponse = HTTPURLResponse(
      url: URL(string: "https://example.com/test")!,
      statusCode: 200,
      httpVersion: "HTTP/1.1",
      headerFields: [
        "Cache-Control" : " max-age=x1,2",
    ])
    XCTAssertNil(malformedNumberResponse?.cacheControlMaxAge)
  }

  func testResponseModification() {
    let modLibResp = libraryCallResponse.modifyingCacheHeaders()
    XCTAssertTrue(modLibResp.hasSufficientCachingHeaders)

    let modMissingMaxAgeResp = missingMaxAgeResponse.modifyingCacheHeaders()
    XCTAssertTrue(modMissingMaxAgeResp.hasSufficientCachingHeaders)

    let noCachingResp = HTTPURLResponse(
      url: URL(string: "https://example.com/test")!,
      statusCode: 200,
      httpVersion: "HTTP/1.1",
      headerFields: nil)!
    XCTAssertFalse(noCachingResp.hasSufficientCachingHeaders)
    XCTAssertTrue(noCachingResp.modifyingCacheHeaders().hasSufficientCachingHeaders)

    let failedResp = HTTPURLResponse(
      url: URL(string: "https://example.com/test")!,
      statusCode: 400,
      httpVersion: "HTTP/1.1",
      headerFields: nil)!
    XCTAssertFalse(failedResp.hasSufficientCachingHeaders)
    XCTAssertFalse(failedResp.modifyingCacheHeaders().hasSufficientCachingHeaders)
  }
}
