//
//  NYPLAxisProgressListenerMock.swift
//  OpenEbooksTests
//
//  Created by Raman Singh on 2021-06-01.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
@testable import SimplyE

class NYPLAxisProgressListenerMock: NYPLAxisDownloadProgressListening {

  var currentProgress: Double = 0.0
  var didTerminate: (() -> Void)?
  var allDownloadsFinished: (() -> Void)?

  func downloadProgressDidUpdate(_ progress: Double) {
    self.currentProgress = progress.roundedToTwoDecimalPlaces
  }

  func downloaderDidTerminate() {
    didTerminate?()
  }
  
  func didFinishAllDownloads() {
    allDownloadsFinished?()
  }

}

extension Double {
  var roundedToTwoDecimalPlaces: Double {
    return (self * 100).rounded()/100
  }
}
