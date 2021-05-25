//
//  AssetWriterMock.swift
//  OpenEbooksTests
//
//  Created by Raman Singh on 2021-05-18.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
@testable import SimplyE

class AssetWriterMock: NYPLAssetWriting {
  
  enum AssetWriterError: Error {
    case someError
  }
  
  var errorToReturn: AssetWriterError?
  var willWriteAsset: (() -> Void)?
  
  init(errorToReturn: AssetWriterError?) {
    self.errorToReturn = errorToReturn
  }
  
  func writeAsset(_ data: Data, atURL url: URL) throws {
    willWriteAsset?()
    if let error = errorToReturn {
      throw error
    } 
  }
  
}
