//
//  NYPLLibraryRegistryFeedRequestHandlerMock.swift
//  SimplyETests
//
//  Created by Ernest Fan on 2021-05-27.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
@testable import SimplyE

class NYPLLibraryRegistryFeedRequestHandlerMock: NYPLLibraryRegistryFeedRequestHandling {
  var libraryAccounts: [Account] = [Account]()
  var requestUrl: URL? = nil
  
  func accounts(_ key: String?) -> [Account] {
    return libraryAccounts
  }
  
  func loadCatalogs(url: URL?, completion: ((Bool) -> ())?) {
    requestUrl = url
    if let completion = completion {
      completion(true)
    }
  }
}
