//
//  NYPLAgeCheckTests.swift
//  Simplified
//
//  Created by Ernest Fan on 2021-03-09.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import XCTest
@testable import SimplyE

class NYPLAgeCheckTests: XCTestCase {

  // Classes/mocks needed for testing
  var ageCheckChoiceStorageMock: NYPLAgeCheckChoiceStorageMock!
  var userAccountProviderMock: NYPLUserAccountProviderMock!
  var simplyeLibraryAccountProviderMock: NYPLCurrentLibraryAccountProviderMock!
  var ageCheck: NYPLAgeCheck!
  
  // NYPLAgeCheck checks the property userAboveAgeLimit in AccountDetails before performing age check
  // This property is store in UserDefault which can be different value when testing on different machine
  // And AccountDetails class is final and not protocol so we cannot override/mock it
  // The workaround here is to store the value of userAboveAgeLimit and restore it after each test
  // This way we can set whatever value we need in each tests, and no need to worry about the default value on different machine
  var defaultUserAboveAgeLimit: Bool!
  
  // Use expectation to test result within closure
  var expectation: XCTestExpectation!
  
  override func setUpWithError() throws {
    try super.setUpWithError()
    
    ageCheckChoiceStorageMock = NYPLAgeCheckChoiceStorageMock()
    simplyeLibraryAccountProviderMock = NYPLCurrentLibraryAccountProviderMock()
    userAccountProviderMock = NYPLUserAccountProviderMock()
    
    defaultUserAboveAgeLimit = simplyeLibraryAccountProviderMock.currentAccount?.details?.userAboveAgeLimit ?? false
    simplyeLibraryAccountProviderMock.currentAccount?.details?.userAboveAgeLimit = false
    
    expectation = self.expectation(description: "AgeChecking")
    
    ageCheck = NYPLAgeCheck(ageCheckChoiceStorage: ageCheckChoiceStorageMock)
  }

  override func tearDownWithError() throws {
    simplyeLibraryAccountProviderMock.currentAccount?.details?.userAboveAgeLimit = defaultUserAboveAgeLimit
  }

  func testAge0() throws {
    ageCheck.verifyCurrentAccountAgeRequirement(userAccountProvider: userAccountProviderMock,
                                                currentLibraryAccountProvider: simplyeLibraryAccountProviderMock) { [weak self] (aboveAgeLimit) in
      XCTAssertFalse(aboveAgeLimit)
      XCTAssertTrue(self?.ageCheckChoiceStorageMock.userPresentedAgeCheck ?? false)
      self?.expectation.fulfill()
    }
    
    let birthYear = Calendar.current.component(.year, from: Date())
    ageCheck.didCompleteAgeCheck(birthYear)
    waitForExpectations(timeout: 1, handler: nil)
  }
  
  func testAge12() throws {
    ageCheck.verifyCurrentAccountAgeRequirement(userAccountProvider: userAccountProviderMock,
                                                currentLibraryAccountProvider: simplyeLibraryAccountProviderMock) { [weak self] (aboveAgeLimit) in
      XCTAssertFalse(aboveAgeLimit)
      XCTAssertTrue(self?.ageCheckChoiceStorageMock.userPresentedAgeCheck ?? false)
      self?.expectation.fulfill()
    }
    
    let birthYear = Calendar.current.component(.year, from: Date()) - 12
    ageCheck.didCompleteAgeCheck(birthYear)
    waitForExpectations(timeout: 1, handler: nil)
  }

  func testAge13() throws {
    ageCheck.verifyCurrentAccountAgeRequirement(userAccountProvider: userAccountProviderMock,
                                                currentLibraryAccountProvider: simplyeLibraryAccountProviderMock) { [weak self] (aboveAgeLimit) in
      XCTAssertFalse(aboveAgeLimit)
      XCTAssertTrue(self?.ageCheckChoiceStorageMock.userPresentedAgeCheck ?? false)
      self?.expectation.fulfill()
    }
    
    let birthYear = Calendar.current.component(.year, from: Date()) - 13
    ageCheck.didCompleteAgeCheck(birthYear)
    waitForExpectations(timeout: 1, handler: nil)
  }
  
  func testAge14() throws {
    ageCheck.verifyCurrentAccountAgeRequirement(userAccountProvider: userAccountProviderMock,
                                                currentLibraryAccountProvider: simplyeLibraryAccountProviderMock) { [weak self] (aboveAgeLimit) in
      XCTAssertTrue(aboveAgeLimit)
      XCTAssertTrue(self?.ageCheckChoiceStorageMock.userPresentedAgeCheck ?? false)
      self?.expectation.fulfill()
    }
    
    let birthYear = Calendar.current.component(.year, from: Date()) - 20
    ageCheck.didCompleteAgeCheck(birthYear)
    waitForExpectations(timeout: 1, handler: nil)
  }
  
  func testAge100() throws {
    ageCheck.verifyCurrentAccountAgeRequirement(userAccountProvider: userAccountProviderMock,
                                                currentLibraryAccountProvider: simplyeLibraryAccountProviderMock) { [weak self] (aboveAgeLimit) in
      XCTAssertTrue(aboveAgeLimit)
      XCTAssertTrue(self?.ageCheckChoiceStorageMock.userPresentedAgeCheck ?? false)
      self?.expectation.fulfill()
    }
    
    let birthYear = Calendar.current.component(.year, from: Date()) - 100
    ageCheck.didCompleteAgeCheck(birthYear)
    waitForExpectations(timeout: 1, handler: nil)
  }
  
  func testAgeCheckFailed() throws {
    // Use an inverted expectation to make sure the completion closure is not executed
    self.expectation.isInverted = true
    ageCheck.verifyCurrentAccountAgeRequirement(userAccountProvider: userAccountProviderMock,
                                                currentLibraryAccountProvider: simplyeLibraryAccountProviderMock) { [weak self] (aboveAgeLimit) in
      self?.expectation.fulfill()
    }
    
    ageCheck.didFailAgeCheck()
    waitForExpectations(timeout: 3, handler: nil)
    
    XCTAssertFalse(ageCheckChoiceStorageMock.userPresentedAgeCheck)
  }
}
