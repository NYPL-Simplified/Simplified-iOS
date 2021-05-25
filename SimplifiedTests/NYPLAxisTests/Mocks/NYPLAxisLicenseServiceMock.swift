//
//  NYPLAxisLicenseServiceMock.swift
//  OpenEbooksTests
//
//  Created by Raman Singh on 2021-05-13.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
@testable import SimplyE

class NYPLAxisLicenseServiceMock: NYPLDownloadRunnerMock, NYPLAxisLicenseHandling {
  
  let aesKeyData: Data?
  
  var willDeleteLicenseFile: (() -> Void)?
  var willDownloadLicenseFile: (() -> Void)?
  var willSaveBookInfo: (() -> Void)?
  var willValidateLicense: (() -> Void)?
  var willReturnAESkeyData: (() -> Void)?
  
  init(itemDownloader: NYPLAxisItemDownloader, shouldSucceed: Bool, aesKeyData: Data?) {
    self.aesKeyData = aesKeyData
    super.init(itemDownloader: itemDownloader, shouldSucceed: shouldSucceed)
  }
  
  func deleteLicenseFile() {
    willDeleteLicenseFile?()
    run()
  }
  
  func downloadLicense() {
    willDownloadLicenseFile?()
    run()
  }
  
  func saveBookInfoForFetchingLicense() {
    willSaveBookInfo?()
    run()
  }
  
  func validateLicense() {
    willValidateLicense?()
    run()
  }
  
  func encryptedContentKeyData() -> Data? {
    willReturnAESkeyData?()
    run()
    return nil
  }
  
  
}
