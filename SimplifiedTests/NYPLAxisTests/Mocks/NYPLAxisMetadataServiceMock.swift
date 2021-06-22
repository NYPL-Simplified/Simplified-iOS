//
//  NYPLAxisMetadataServiceMock.swift
//  OpenEbooksTests
//
//  Created by Raman Singh on 2021-05-17.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
@testable import SimplyE

struct NYPLAxisMetadataServiceMock: NYPLAxisMetadataContentHandling {
  
  enum NYPLAxisMetadataServiceMockError: Error {
    case dummyError
  }
  
  let shouldSucceed: Bool
  
  func downloadMetadataTasks() -> [NYPLAxisTask] {
    let t = NYPLAxisTask() { task in
      if self.shouldSucceed {
        task.succeeded()
      } else {
        task.failed(with: NYPLAxisMetadataServiceMockError.dummyError)
      }
    }
    
    return [t]
  }
  
  
  

}
