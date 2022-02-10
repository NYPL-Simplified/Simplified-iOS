//
//  NYPLSignInBusinessLogicTests.swift
//  SimplyETests
//
//  Created by Ettore Pasquini on 10/14/20.
//  Copyright © 2020 NYPL. All rights reserved.
//

import XCTest
@testable import SimplyE

class NYPLSignInBusinessLogicTests: XCTestCase {
  var businessLogic: NYPLSignInBusinessLogic!
  var libraryAccountMock: NYPLLibraryAccountMock!
  var drmAuthorizerAdobe: NYPLDRMAuthorizingMock!
  var drmAuthorizerAxis: NYPLDRMAuthorizingMock!
  var uiDelegate: NYPLSignInOutBusinessLogicUIDelegateMock!

  override func setUpWithError() throws {
    try super.setUpWithError()
    libraryAccountMock = NYPLLibraryAccountMock()
    drmAuthorizerAdobe = NYPLDRMAuthorizingMock()
    drmAuthorizerAxis = NYPLDRMAuthorizingMock()
    uiDelegate = NYPLSignInOutBusinessLogicUIDelegateMock()
    businessLogic = NYPLSignInBusinessLogic(
      libraryAccountID: libraryAccountMock.NYPLAccountUUID,
      libraryAccountsProvider: libraryAccountMock,
      urlSettingsProvider: NYPLURLSettingsProviderMock(),
      bookRegistry: NYPLBookRegistryMock(),
      bookDownloadsCenter: NYPLMyBooksDownloadsCenterMock(),
      userAccountProvider: NYPLUserAccountMock.self,
      networkExecutor: NYPLRequestExecutorMock(),
      uiDelegate: uiDelegate,
      drmAuthorizerAdobe: drmAuthorizerAdobe,
      drmAuthorizerAxis: drmAuthorizerAxis)
  }

  override func tearDownWithError() throws {
    print("tearDownWithError")
    try super.tearDownWithError()
    businessLogic.userAccount.removeAll()
    businessLogic = nil
    libraryAccountMock = nil
    drmAuthorizerAdobe = nil
    uiDelegate = nil
  }

  func testUpdateUserAccountWithNoSelectedAuthentication() throws {
    // preconditions
    let user = businessLogic.userAccount
    XCTAssertNotEqual(user.barcode, "newBarcode")
    XCTAssertNotEqual(user.PIN, "newPIN")

    // test
    businessLogic.updateUserAccount(forDRMAuthorization: true,
                                    withBarcode: "newBarcode",
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
    businessLogic.updateUserAccount(forDRMAuthorization: true,
                                    withBarcode: "newBarcode",
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
    XCTAssertNil(user.authToken, "user.authToken precondition should be nil")
    XCTAssertNil(user.patron, "user.patron precondition should be nil")
    XCTAssertNil(user.cookies, "user.cookies precondition should be nil")
    businessLogic.selectedAuthentication = libraryAccountMock.cleverAuthentication
    let patron = ["name": "ciccio"]

    // test
    businessLogic.updateUserAccount(forDRMAuthorization: true,
                                    withBarcode: nil,
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
    businessLogic.updateUserAccount(forDRMAuthorization: true,
                                    withBarcode: nil,
                                    pin: nil,
                                    authToken: "some-great-token",
                                    patron: patron,
                                    cookies: cookies)

    // verification
    XCTAssertEqual(user.authToken, "some-great-token")
    XCTAssertEqual(user.patron!["name"] as! String, "Ciccio")
    XCTAssertEqual(user.cookies, cookies)
  }

  func testMakeSignInRequest() throws {
    // test sign-in request for barcode auth
    businessLogic.selectedAuthentication = libraryAccountMock.barcodeAuthentication
    let barcodeReq = businessLogic.makeRequest(for: .signIn, context: "barcode request test")
    XCTAssertNotNil(barcodeReq)
    let barcodeHeaderValue = barcodeReq?.value(forHTTPHeaderField: "Authorization")
    XCTAssertFalse(barcodeHeaderValue?.starts(with: "Bearer") ?? false)

    // prerequisite for both OAuth and SAML
    businessLogic.authToken = "tekken"

    // test sign-in request for oauth auth
    businessLogic.selectedAuthentication = libraryAccountMock.oauthAuthentication
    let oauthReq = businessLogic.makeRequest(for: .signIn, context: "oauth request test")
    XCTAssertNotNil(oauthReq)
    let oauthHeaderValue = oauthReq?.value(forHTTPHeaderField: "Authorization")
    XCTAssertTrue(oauthHeaderValue?.starts(with: "Bearer") ?? false)

    // test sign-in request for saml auth
    businessLogic.selectedAuthentication = libraryAccountMock.samlAuthentication
    let samlReq = businessLogic.makeRequest(for: .signIn, context: "saml request test")
    XCTAssertNotNil(samlReq)
    let samlHeaderValue = samlReq?.value(forHTTPHeaderField: "Authorization")
    XCTAssertTrue(samlHeaderValue?.starts(with: "Bearer") ?? false)
  }

  func testCardCreatorSupport() {
    #if SIMPLYE
    XCTAssertTrue(businessLogic.registrationViaCardCreatorIsPossible())
    XCTAssertTrue(businessLogic.registrationIsPossible())
    guard let cardCreatorConfig = businessLogic.makeCardCreationConfiguration() else {
      XCTFail("Unable to create card creator config")
      return
    }
    XCTAssertEqual(cardCreatorConfig.endpointUsername, NYPLSecrets.cardCreatorUsername)
    XCTAssertEqual(cardCreatorConfig.endpointPassword, NYPLSecrets.cardCreatorPassword)
    XCTAssertGreaterThan(cardCreatorConfig.requestTimeoutInterval, 10)
    #else
    XCTAssertFalse(businessLogic.registrationViaCardCreatorIsPossible())
    XCTAssertFalse(businessLogic.registrationIsPossible())
    #endif
  }

  func testLogInFlow() throws {
    // preconditions
    let user = businessLogic.userAccount
    XCTAssertNil(user.deviceID, "user.deviceID precondition should be nil")
    XCTAssertNil(user.userID, "user.userID precondition should be nil")
    XCTAssertNil(user.username, "user.username precondition should be nil")
    XCTAssertNil(user.barcode, "user.barcode precondition should be nil")
    XCTAssertNil(user.pin, "user.pin precondition should be nil")

    let expect = expectation(forNotification: .NYPLIsSigningIn, object: nil) { notif -> Bool in
      let isSigningIn = notif.object as! Bool
      // sanity verification
      XCTAssertNotNil(user)
      XCTAssertNotNil(self.drmAuthorizerAdobe)

      if isSigningIn == false {
        // verification
        XCTAssertFalse(self.businessLogic.isValidatingCredentials)
        #if SIMPLYE //TODO: IOS-336
        XCTAssertNotNil(user.deviceID)
        XCTAssertEqual(user.deviceID, self.drmAuthorizerAdobe.deviceID)
        XCTAssertEqual(user.userID, self.drmAuthorizerAdobe.userID)
        #endif
        XCTAssertEqual(user.username, self.uiDelegate.username)
        XCTAssertEqual(user.barcode, self.uiDelegate.username)
        XCTAssertEqual(user.pin, self.uiDelegate.pin)
      }

      return !isSigningIn
    }

    // test
    businessLogic.selectedAuthentication = libraryAccountMock.barcodeAuthentication
    businessLogic.logIn()
    XCTAssertTrue(businessLogic.isValidatingCredentials)

    wait(for: [expect], timeout: 5)
  }
}
