//
//  NYPLAxisLibraryService.swift
//  SimplyE
//
//  Created by Raman Singh on 2021-05-18.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
import R2Shared

struct NYPLAxisLibraryService: DRMLibraryService {
  
  let protectedAssetHandler: NYPLAxisProtectedAssetHandling
  
  var contentProtection: ContentProtection? {
    return NYPLAxisContentProtection(protectedAssetHandler: protectedAssetHandler)
  }
  
  /// I did not see this getting called anywhere in the code so left it to return true assuming this is the safest option.
  func canFulfill(_ file: URL) -> Bool {
    return true
  }
  
  func fulfill(_ file: URL) -> Deferred<DRMFulfilledPublication, Error> {
    return deferred { completion in
      completion(.success(DRMFulfilledPublication(
        localURL: file,
        suggestedFilename: file.lastPathComponent
      )))
    }
  }
}
