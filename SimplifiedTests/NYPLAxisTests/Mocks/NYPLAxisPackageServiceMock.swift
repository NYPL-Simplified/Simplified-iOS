//
//  NYPLAxisPackageServiceMock.swift
//  OpenEbooksTests
//
//  Created by Raman Singh on 2021-05-17.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
@testable import SimplyE

struct NYPLAxisPackageServiceMock: NYPLAxisPackageHandling {
  
  enum NYPLAxisPackageServiceMockError: Error {
    case dummyError
  }
  
  let shouldSucceed: Bool
  
  func makeDownloadPackageContentTasks() -> [NYPLAxisTask] {
    let t = NYPLAxisTask() { task in
      if self.shouldSucceed {
        task.succeeded()
      } else {
        task.failed(with: NYPLAxisPackageServiceMockError.dummyError)
      }
    }
    
    return [t]
  }
  
  func cancelPackageDownload(with error: NYPLAxisError) {}
  
}
