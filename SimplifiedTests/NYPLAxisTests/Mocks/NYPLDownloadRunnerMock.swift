//
//  NYPLDownloadRunnerMock.swift
//  OpenEbooksTests
//
//  Created by Raman Singh on 2021-05-17.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
@testable import SimplyE

class NYPLDownloadRunnerMock {
  
  let shouldSucceed: Bool
  let itemDownloader: NYPLAxisItemDownloader
  
  init(itemDownloader: NYPLAxisItemDownloader, shouldSucceed: Bool) {
    self.itemDownloader = itemDownloader
    self.shouldSucceed = shouldSucceed
  }
  
  func run() {
    itemDownloader.tasksSynchnorizer.startSynchronizedTask()
    if shouldSucceed {
      itemDownloader.tasksSynchnorizer.endSynchronizedTask()
    } else {
      itemDownloader.terminateDownloadProcess()
    }
  }
  
}
