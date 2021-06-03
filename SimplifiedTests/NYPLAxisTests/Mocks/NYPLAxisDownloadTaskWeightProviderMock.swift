//
//  NYPLAxisDownloadTaskWeightProviderMock.swift
//  OpenEbooksTests
//
//  Created by Raman Singh on 2021-06-01.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import XCTest
@testable import SimplyE

struct NYPLAxisDownloadTaskWeightProviderMock: NYPLAxisWeightProviding {
  
  let weights: [URL: Double]
  
  func fixedWeightForTaskWithURL(_ url: URL) -> Double? {
    return weights[url]
  }
  
}
