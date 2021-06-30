//
//  NYPLAxisXMLTests.swift
//  OpenEbooksTests
//
//  Created by Raman Singh on 2021-05-18.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import XCTest
import NYPLAxis
@testable import SimplyE

class NYPLAxisXMLTests: XCTestCase {
  
  lazy private var xml: NYPLAxisXML? = {
    let itemURL = Bundle(for: NYPLAxisXMLTests.self)
      .url(forResource: "DummyCatalog", withExtension: "xml")!
    let data = try? Data(contentsOf: itemURL)
    return NYPLAxisXMLRepresentation(data: data)
  }()
  
  func testAxisXMLShouldInitWithXMLData() {
    XCTAssertNotNil(xml)
  }
  
  func testAxisXMLShouldFindFirstItemWithGivenKey() {
    var actual = xml?.findFirstRecursivelyInAttributes("description")
    var expected = "Cardigan Sweater"
    XCTAssertEqual(actual, expected)
    
    actual = xml?.findFirstRecursivelyInAttributes("product_image")
    expected = "cardigan.jpg"
    XCTAssertEqual(actual, expected)
  }
  
  func testAxisXMLShouldFindAllItemsWithGivenKey() {
    let allGenders = xml?.findRecursivelyInAttributes("gender") ?? []
    XCTAssertTrue(allGenders.contains("Men's"))
    XCTAssertTrue(allGenders.contains("Women's"))
    XCTAssertEqual(allGenders.count, 2)
    
    let allDescriptions = xml?.findRecursivelyInAttributes("description") ?? []
    XCTAssertTrue(allDescriptions.contains("Small"))
    XCTAssertTrue(allDescriptions.contains("Medium"))
    XCTAssertTrue(allDescriptions.contains("Large"))
    XCTAssertTrue(allDescriptions.contains("Extra Large"))
    
    let allImages = xml?.findRecursivelyInAttributes("image") ?? []
    XCTAssertTrue(allImages.contains("red_cardigan.jpg"))
    XCTAssertTrue(allImages.contains("burgundy_cardigan.jpg"))
    XCTAssertTrue(allImages.contains("navy_cardigan.jpg"))
    XCTAssertTrue(allImages.contains("black_cardigan.jpg"))
  }
  
}
