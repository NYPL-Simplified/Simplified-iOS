//
//  NYPLLibraryFinderBusinessLogic.swift
//  Simplified
//
//  Created by Ernest Fan on 2021-04-21.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

protocol NYPLLibraryFinderDataProviding {
  var userAccounts: [Account] { get }
  var newLibraryAccounts: [Account] { get }
  
  // Might need to add pagination to the request
  func requestLibraryList(searchKeyword: String?, completion: @escaping (Error?) -> ())
}

class NYPLLibraryFinderBusinessLogic: NSObject, NYPLLibraryFinderDataProviding {
  var userAccounts: [Account]
  var newLibraryAccounts: [Account]
  
  init(userAccounts: [Account] = [Account](), newLibraryAccounts: [Account] = [Account]()) {
    // TODO: iOS-35 Fetch library list from new API endpoints
    self.userAccounts = userAccounts
    self.newLibraryAccounts = newLibraryAccounts
  }
  
  func requestLibraryList(searchKeyword: String?, completion: @escaping (Error?) -> ()) {
    // TODO: iOS-35 Perform API request with query keyword
    // TODO: iOS-34 Add location information to request
    
    // For testing
    Log.debug(#file, "API Request - request library list with keyword - \(searchKeyword)")
    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
      completion(nil)
    }
  }
}
