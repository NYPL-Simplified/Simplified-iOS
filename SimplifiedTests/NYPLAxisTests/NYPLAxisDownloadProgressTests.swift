//
//  NYPLAxisDownloadProgressTests.swift
//  OpenEbooksTests
//
//  Created by Raman Singh on 2021-06-01.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import XCTest
@testable import SimplyE

class NYPLAxisDownloadProgressTests: XCTestCase {

  private let keysProvider = NYPLAxisKeysProvider()
  private let licenseURL = URL(string: "www.mock.com/license")!
  private let containerURL = URL(string: "www.mock.com/container")!
  private let encryptionURL = URL(string: "www.mock.com/encryption")!
  private let packageURL = URL(string: "www.mock.com/package")!
  private let chapter1URL = URL(string: "www.mock.com/chapter1")!
  private let chapter2URL = URL(string: "www.mock.com/chapter2")!
  private let chapter3URL = URL(string: "www.mock.com/chapter3")!

  private let progressListener = NYPLAxisProgressListenerMock()

  lazy private var sut: NYPLAxisDownloadProgress = {
    let axisDownloadProcess = NYPLAxisDownloadProgress()
    axisDownloadProcess.progressListener = self.progressListener
    return axisDownloadProcess
  }()

  override func tearDown() {
    super.tearDown()
    sut.test_reset()
  }

  func testDownloadingFixedWeightItemsShouldUpdateDownloadProgress() {
    sut.addFixedWeightTask(with: licenseURL, weight: 0.05)
    sut.addFixedWeightTask(with: containerURL, weight: 0.05)

    XCTAssertEqual(progressListener.currentProgress, 0.0)

    sut.didFinishTask(with: licenseURL)
    // 5 % downloaded
    XCTAssertEqual(progressListener.currentProgress, 0.05)

    sut.addFixedWeightTask(with: encryptionURL, weight: 0.4)
    // 5 % downloaded
    XCTAssertEqual(progressListener.currentProgress, 0.05)

    sut.didFinishTask(with: encryptionURL)
    // 45 % downloaded
    XCTAssertEqual(progressListener.currentProgress, 0.45)
  }

  func testDownloadingFlexibleWeightItemShouldUpdateDownloadProgress() {
    sut.addFixedWeightTask(with: licenseURL, weight: 0.05)
    sut.addFixedWeightTask(with: containerURL, weight: 0.05)
    sut.addFlexibleWeightTask(with: chapter1URL)
    sut.addFlexibleWeightTask(with: chapter2URL)

    XCTAssertEqual(progressListener.currentProgress, 0.0)

    sut.didFinishTask(with: chapter1URL)
    // 45 % downloaded
    XCTAssertEqual(progressListener.currentProgress, 0.45)

    sut.didFinishTask(with: chapter2URL)
    // 90% downloaded
    XCTAssertEqual(progressListener.currentProgress, 0.9)
  }

  func testAddingMoreItemsShouldNotChangeCurrentDownloadProgress() {
    sut.addFixedWeightTask(with: licenseURL, weight: 0.05)
    sut.addFixedWeightTask(with: containerURL, weight: 0.05)
    sut.addFlexibleWeightTask(with: chapter1URL)
    sut.addFlexibleWeightTask(with: chapter2URL)

    XCTAssertEqual(progressListener.currentProgress, 0.0)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: licenseURL), 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: containerURL), 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter1URL), 0.45)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter2URL), 0.45)

    sut.didFinishTask(with: chapter1URL)
    // 45 % downloaded
    XCTAssertEqual(progressListener.currentProgress, 0.45)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: licenseURL), 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: containerURL), 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter1URL), 0.45)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter2URL), 0.45)

    sut.addFlexibleWeightTask(with: encryptionURL)
    // 45 % downloaded
    XCTAssertEqual(progressListener.currentProgress, 0.45)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: licenseURL), 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: containerURL), 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter1URL), 0.45)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter2URL), 0.225)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: encryptionURL), 0.225)
  }

  func testAddingMoreTasksShouldChangeWeightOfUnfinishedFlexibleItems() {
    sut.addFixedWeightTask(with: licenseURL, weight: 0.05)
    sut.addFlexibleWeightTask(with: chapter1URL)

    XCTAssertEqual(progressListener.currentProgress, 0.0)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: licenseURL), 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter1URL), 0.95)

    sut.didFinishTask(with: licenseURL)
    // 5 % downloaded
    XCTAssertEqual(progressListener.currentProgress, 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter1URL), 0.95)

    sut.addFlexibleWeightTask(with: chapter2URL)
    XCTAssertEqual(progressListener.currentProgress, 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: licenseURL), 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter1URL), 0.95/2)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter2URL), 0.95/2)

    sut.addFixedWeightTask(with: containerURL, weight: 0.05)
    XCTAssertEqual(progressListener.currentProgress, 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: licenseURL), 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: containerURL), 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter1URL), 0.45)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter2URL), 0.45)

    sut.addFlexibleWeightTask(with: chapter3URL)
    XCTAssertEqual(progressListener.currentProgress, 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: licenseURL), 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: containerURL), 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter1URL), 0.3)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter2URL), 0.3)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter3URL), 0.3)

    sut.addFixedWeightTask(with: encryptionURL, weight: 0.05)
    XCTAssertEqual(progressListener.currentProgress, 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: licenseURL), 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: containerURL), 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: encryptionURL), 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter1URL), 0.85/3)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter2URL), 0.85/3)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter3URL), 0.85/3)

    // 10 % completed
    sut.didFinishTask(with: encryptionURL)
    XCTAssertEqual(progressListener.currentProgress, 0.1)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: licenseURL), 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: containerURL), 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: encryptionURL), 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter1URL), 0.85/3)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter2URL), 0.85/3)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter3URL), 0.85/3)

    // 15 % completed
    sut.didFinishTask(with: containerURL)
    XCTAssertEqual(progressListener.currentProgress, 0.15)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: licenseURL), 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: containerURL), 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: encryptionURL), 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter1URL), 0.85/3)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter2URL), 0.85/3)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter3URL), 0.85/3)

    // 43% completed
    sut.didFinishTask(with: chapter2URL)
    XCTAssertEqual(progressListener.currentProgress, (0.15 + (0.85/3)).roundedToTwoDecimalPlaces)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: licenseURL), 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: containerURL), 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: encryptionURL), 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter1URL), 0.85/3)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter2URL), 0.85/3)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter3URL), 0.85/3)
  }

  func testAddingMoreTasksShouldNotAffectWeightOfCompletedTasks() {
    sut.addFixedWeightTask(with: licenseURL, weight: 0.2)
    sut.addFlexibleWeightTask(with: chapter1URL)
    sut.addFlexibleWeightTask(with: chapter2URL)

    XCTAssertEqual(progressListener.currentProgress, 0.0)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: licenseURL), 0.2)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter1URL), 0.4)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter2URL), 0.4)
    
    // 60 % completed
    sut.didFinishTask(with: licenseURL)
    sut.didFinishTask(with: chapter1URL)
    XCTAssertEqual(progressListener.currentProgress, 0.6)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: licenseURL), 0.2)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter1URL), 0.4)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter2URL), 0.4)

    sut.addFlexibleWeightTask(with: chapter3URL)
    XCTAssertEqual(progressListener.currentProgress, 0.6)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: licenseURL), 0.2)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter1URL), 0.4)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter2URL), 0.2)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter3URL), 0.2)
    
    sut.addFixedWeightTask(with: encryptionURL, weight: 0.3)
    XCTAssertEqual(progressListener.currentProgress, 0.6)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: licenseURL), 0.2)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter1URL), 0.4)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter2URL)?.roundedToTwoDecimalPlaces, 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter3URL)?.roundedToTwoDecimalPlaces, 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: encryptionURL), 0.3)
  }

  func testShouldAutomaticallyAdjustWeightToAcomodateItemWithIllegalWeight() {
    sut.addFixedWeightTask(with: licenseURL, weight: 0.2)
    XCTAssertEqual(progressListener.currentProgress, 0.0)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: licenseURL), 0.2)

    sut.addFixedWeightTask(with: containerURL, weight: 0.9)
    XCTAssertEqual(progressListener.currentProgress, 0.0)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: licenseURL), 0.2)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: containerURL), 0.8)

    sut.addFlexibleWeightTask(with: chapter1URL)
    XCTAssertEqual(progressListener.currentProgress, 0.0)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: licenseURL), 0.2)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: containerURL), 0.4)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter1URL), 0.4)

    sut.addFixedWeightTask(with: encryptionURL, weight: 3.5)
    XCTAssertEqual(progressListener.currentProgress, 0.0)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: licenseURL), 0.2)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: containerURL), 0.8/3)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter1URL), 0.8/3)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: encryptionURL), 0.8/3)

    sut.addFixedWeightTask(with: packageURL, weight: -5.5)
    XCTAssertEqual(progressListener.currentProgress, 0.0)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: licenseURL), 0.2)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: containerURL), 0.2)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter1URL), 0.2)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: encryptionURL), 0.2)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: packageURL), 0.2)

    sut.addFixedWeightTask(with: chapter2URL, weight: 1000.0)
    XCTAssertEqual(progressListener.currentProgress, 0.0)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: licenseURL), 0.2)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: containerURL), 0.16)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter1URL), 0.16)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: encryptionURL), 0.16)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: packageURL), 0.16)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter2URL), 0.16)

    // 20 % completed
    sut.didFinishTask(with: licenseURL)
    XCTAssertEqual(progressListener.currentProgress, 0.2)

    // 36 % completed
    sut.didFinishTask(with: containerURL)
    XCTAssertEqual(progressListener.currentProgress, 0.36)

    // 52 % completed
    sut.didFinishTask(with: chapter1URL)
    XCTAssertEqual(progressListener.currentProgress, 0.52)

    // 68 % completed
    sut.didFinishTask(with: encryptionURL)
    XCTAssertEqual(progressListener.currentProgress, 0.68)

    // 84 % completed
    sut.didFinishTask(with: packageURL)
    XCTAssertEqual(progressListener.currentProgress, 0.84)

    // 100 % completed
    sut.didFinishTask(with: chapter2URL)
    XCTAssertEqual(progressListener.currentProgress, 1.0)
  }

  func testAddingNewProcessToAlreadyFullProcessShouldNotAffectProgress() {
    sut.addFixedWeightTask(with: licenseURL, weight: 0.2)
    sut.addFixedWeightTask(with: containerURL, weight: 0.8)
    
    XCTAssertEqual(progressListener.currentProgress, 0.0)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: licenseURL), 0.2)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: containerURL), 0.8)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: packageURL), nil)
    
    sut.addFixedWeightTask(with: packageURL, weight: 0.5)
    
    XCTAssertEqual(progressListener.currentProgress, 0.0)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: licenseURL), 0.2)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: containerURL), 0.8)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: packageURL), nil)
  }

  func testAddingNewProcessToACompletedDownloadProcessShouldNotAffectProgress() throws {
    sut.addFixedWeightTask(with: licenseURL, weight: 0.05)
    sut.addFixedWeightTask(with: containerURL, weight: 0.05)
    sut.addFlexibleWeightTask(with: chapter1URL)
    sut.addFlexibleWeightTask(with: chapter2URL)

    sut.didFinishTask(with: licenseURL)
    sut.didFinishTask(with: containerURL)
    sut.didFinishTask(with: chapter1URL)
    sut.didFinishTask(with: chapter2URL)

    XCTAssertEqual(progressListener.currentProgress, 1.0)
    
    sut.addFlexibleWeightTask(with: chapter3URL)
    sut.addFixedWeightTask(with: packageURL, weight: 0.05)
    
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: licenseURL), 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: containerURL), 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter1URL), 0.45)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter2URL), 0.45)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter3URL), nil)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: packageURL), nil)
    
    sut.didFinishTask(with: chapter3URL)
    sut.didFinishTask(with: packageURL)
    
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: licenseURL), 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: containerURL), 0.05)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter1URL), 0.45)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter2URL), 0.45)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: chapter3URL), nil)
    XCTAssertEqual(sut.test_getWeightForProcess(withURL: packageURL), nil)
  }

}
