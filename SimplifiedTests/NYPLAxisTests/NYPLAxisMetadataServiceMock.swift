//
//  NYPLAxisMetadataServiceMock.swift
//  OpenEbooksTests
//
//  Created by Raman Singh on 2021-05-17.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
@testable import SimplyE

class NYPLAxisMetadataServiceMock: NYPLDownloadRunnerMock, NYPLAxisMetadataContentHandling {
  
  func downloadContent() {
    run()
  }

}
