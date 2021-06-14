//
//  NYPLPackagePathPrefixProviderTests.swift
//  OpenEbooksTests
//
//  Created by Raman Singh on 2021-06-14.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import XCTest
@testable import SimplyE

class NYPLPackagePathPrefixProviderTests: XCTestCase {
  
  func test_pathPrefixProvider_shouldProvidePrefixForPath_ifSubdirectoryExists() {
    let pathPrefixProvider = NYPLAxisPackagePathPrefixProvider()
    let result = pathPrefixProvider.getPackagePathPrefix(packageEndpoint: "OPS/abcd.opf")
    let expected = "OPS/"
    XCTAssertEqual(result, expected)
  }
  
  func test_pathPrefixProvider_shouldProvidePrefixForPath_ifSubdirectoriesExist() {
    let pathPrefixProvider = NYPLAxisPackagePathPrefixProvider()
    let result = pathPrefixProvider.getPackagePathPrefix(packageEndpoint: "OPS/XYZ/abcd.opf")
    let expected = "OPS/XYZ/"
    XCTAssertEqual(result, expected)
  }
  
  func test_pathPrefixProvider_shouldNotProvidePrefixForPath_ifNoSubdirectoriesExist() {
    let pathPrefixProvider = NYPLAxisPackagePathPrefixProvider()
    let result = pathPrefixProvider.getPackagePathPrefix(packageEndpoint: "abcd.opf")
    XCTAssertNil(result)
  }
  
}
