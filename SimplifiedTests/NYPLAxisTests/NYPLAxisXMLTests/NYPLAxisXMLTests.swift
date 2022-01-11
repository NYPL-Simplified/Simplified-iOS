//
//  NYPLAxisXMLTests.swift
//  OpenEbooksTests
//
//  Created by Raman Singh on 2021-05-18.
//  Copyright © 2021 NYPL. All rights reserved.
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

  func testFindFirstNodeNamed() {
    let catalogItem = xml?.firstNodeNamed("catalog_item")
    XCTAssertEqual(catalogItem?.attributes["gender"] as? String, "Men's")
    XCTAssertNil(xml?.firstNodeNamed("not_there"))
  }
  
  func testAxisXMLShouldFindAllItemsWithGivenKey() {
    let product = xml!.firstNodeNamed("product")!
    let allGenders = product.attributeValues(forKey: "gender",
                                                 onNodesNamed: "catalog_item")
    XCTAssertTrue(allGenders.contains("Men's"))
    XCTAssertTrue(allGenders.contains("Women's"))
    XCTAssertEqual(allGenders.count, 2)

    let catalogItem = product.firstNodeNamed("catalog_item")!
    let allSizes = catalogItem.attributeValues(forKey: "description",
                                                   onNodesNamed: "size")
    XCTAssert(allSizes.contains("Small"))
    XCTAssert(allSizes.contains("Medium"))
    XCTAssert(allSizes.contains("Large"))
    XCTAssertEqual(allSizes.count, 3)
  }
}
