//
//  NYPLSignInBusinessLogicTests.swift
//  SimplyETests
//
//  Created by Ettore Pasquini on 10/14/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import XCTest
@testable import SimplyE

class NYPLSignInBusinessLogicTests: XCTestCase {
  var businessLogic: NYPLSignInBusinessLogic!
  var libraryAccountMock: NYPLLibraryAccountMock!

  override func setUpWithError() throws {
    try super.setUpWithError()
    libraryAccountMock = NYPLLibraryAccountMock()
    businessLogic = NYPLSignInBusinessLogic(
      libraryAccountID: libraryAccountMock.NYPLAccountUUID,
      libraryAccountsProvider: libraryAccountMock,
      bookRegistry: NYPLBookRegistryMock(),
      userAccountProvider: NYPLUserAccountMock.self,
      uiDelegate: nil,
      drmAuthorizer: nil)
  }

  override func tearDownWithError() throws {
    try super.tearDownWithError()
    businessLogic.userAccount.removeAll()
    businessLogic = nil
    libraryAccountMock = nil
  }

  func testUpdateUserAccountWithNoSelectedAuthentication() throws {
    // preconditions
    let user = businessLogic.userAccount
    XCTAssertNotEqual(user.barcode, "newBarcode")
    XCTAssertNotEqual(user.PIN, "newPIN")

    // test
    businessLogic.updateUserAccount(withBarcode: "newBarcode",
                                    pin: "newPIN",
                                    authToken: nil,
                                    patron: nil,
                                    cookies: nil)

    // verification
    XCTAssertEqual(user.barcode, "newBarcode")
    XCTAssertEqual(user.PIN, "newPIN")
  }

  func testUpdateUserAccountWithBarcodeAuthentication() throws {
    // preconditions
    let user = businessLogic.userAccount
    XCTAssertNotEqual(user.barcode, "newBarcode")
    XCTAssertNotEqual(user.PIN, "newPIN")
    businessLogic.selectedAuthentication = libraryAccountMock.barcodeAuthentication

    // test
    businessLogic.updateUserAccount(withBarcode: "newBarcode",
                                    pin: "newPIN",
                                    authToken: nil,
                                    patron: nil,
                                    cookies: nil)

    // verification
    XCTAssertEqual(user.barcode, "newBarcode")
    XCTAssertEqual(user.PIN, "newPIN")
  }

  func testUpdateUserAccountWithCleverAuthentication() throws {
    // preconditions
    let user = businessLogic.userAccount
    XCTAssertNil(user.authToken)
    XCTAssertNil(user.patron)
    XCTAssertNil(user.cookies)
    businessLogic.selectedAuthentication = libraryAccountMock.cleverAuthentication
    let patron = ["name": "ciccio"]

    // test
    businessLogic.updateUserAccount(withBarcode: nil,
                                    pin: nil,
                                    authToken: "some-great-token",
                                    patron: patron,
                                    cookies: nil)

    // verification
    XCTAssertEqual(user.authToken, "some-great-token")
    XCTAssertEqual(user.patron!["name"] as! String, "ciccio")
  }

  func testUpdateUserAccountWithSAMLAuthentication() throws {
    // preconditions
    let user = businessLogic.userAccount
    XCTAssertNil(user.authToken)
    XCTAssertNil(user.patron)
    XCTAssertNil(user.cookies)
    XCTAssertTrue(businessLogic.isSamlPossible())
    businessLogic.selectedAuthentication = libraryAccountMock.samlAuthentication
    let patron = ["name": "Ciccio"]
    let cookies = [HTTPCookie(properties: [
      .domain: "www.example.com",
      .path: "test",
      .name: "biscottino",
      .value: "chocolate"
    ])!]

    // test
    businessLogic.updateUserAccount(withBarcode: nil,
                                    pin: nil,
                                    authToken: "some-great-token",
                                    patron: patron,
                                    cookies: cookies)

    // verification
    XCTAssertEqual(user.authToken, "some-great-token")
    XCTAssertEqual(user.patron!["name"] as! String, "Ciccio")
    XCTAssertEqual(user.cookies, cookies)
  }

}
