//
//  TerminationListenerMock.swift
//  OpenEbooksTests
//
//  Created by Raman Singh on 2021-05-18.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
@testable import SimplyE

class TerminationListenerMock: NYPLAxisItemDownloadTerminationListening {
  
  var didTerminate: (() -> Void)?
  
  func downloaderDidTerminate() {
    didTerminate?()
  }
  
}
