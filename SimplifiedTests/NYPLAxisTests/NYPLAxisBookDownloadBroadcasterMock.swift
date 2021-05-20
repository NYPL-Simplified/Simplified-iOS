//
//  NYPLAxisBookDownloadBroadcasterMock.swift
//  OpenEbooksTests
//
//  Created by Raman Singh on 2021-05-17.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
@testable import SimplyE

class NYPLAxisBookDownloadBroadcasterMock: NYPLBookDownloadBroadcasting {
  
  var downloadSuccessful: (() -> Void)?
  var downloadFailed: (() -> Void)?
  
  func failDownloadWithAlert(forBook book: NYPLBook) {
    downloadFailed?()
  }
  
  func replaceBook(_ book: NYPLBook, withFileAtURL sourceLocation: URL,
                   forDownloadTask downloadtask: URLSessionDownloadTask) -> Bool {
    
    downloadSuccessful?()
    return true
  }
  
}
