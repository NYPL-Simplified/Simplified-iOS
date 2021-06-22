//
//  NYPLAxisLicenseServiceMock.swift
//  OpenEbooksTests
//
//  Created by Raman Singh on 2021-05-13.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
@testable import SimplyE

class NYPLAxisLicenseServiceMock: NYPLAxisLicenseHandling {
  
  enum NYPLAxisLicenseServiceMockError: Error {
    case dummyError
  }
  
  
  let aesKeyData: Data?
  let shouldSucceed: Bool
  let licenseDownloadTask: NYPLAxisTask?
  
  var willDeleteLicenseFile: (() -> Void)?
  var willDownloadLicenseFile: (() -> Void)?
  var willSaveBookInfo: (() -> Void)?
  var willValidateLicense: (() -> Void)?
  var willReturnAESkeyData: (() -> Void)?
  
  init(shouldSucceed: Bool, aesKeyData: Data?, downloadLicenseTask: NYPLAxisTask? = nil) {
    self.aesKeyData = aesKeyData
    self.shouldSucceed = shouldSucceed
    self.licenseDownloadTask = downloadLicenseTask
  }
  
  func makeDownloadLicenseTask() -> NYPLAxisTask {
    willDownloadLicenseFile?()
    return licenseDownloadTask ?? dummyTask()
  }
  
  func makeValidateLicenseTask() -> NYPLAxisTask {
    willValidateLicense?()
    return dummyTask()
  }
  
  func makeSaveBookInfoTask() -> NYPLAxisTask {
    willSaveBookInfo?()
    return dummyTask()
  }
  
  func makeDeleteLicenseTask() -> NYPLAxisTask {
    willDeleteLicenseFile?()
    return dummyTask()
  }
  
  private func dummyTask() -> NYPLAxisTask {
    return NYPLAxisTask() { task in
      if self.shouldSucceed {
        task.succeeded()
      } else {
        task.failed(with: NYPLAxisLicenseServiceMockError.dummyError)
      }
    }
  }
  
  func encryptedContentKeyData() -> Data? {
    willReturnAESkeyData?()
    return nil
  }
  
}
