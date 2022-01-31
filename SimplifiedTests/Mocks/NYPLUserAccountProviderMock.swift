//
//  NYPLUserAccountProviderMock.swift
//  SimplyETests
//
//  Created by Ernest Fan on 2021-03-11.
//  Copyright © 2021 NYPL. All rights reserved.
//

import Foundation
@testable import SimplyE

class NYPLUserAccountProviderMock: NSObject, NYPLUserAccountProvider {
  private static let userAccountMock = NYPLUserAccountMock()
  
  var needsAuth: Bool
  
  static func sharedAccount(libraryUUID: String?) -> NYPLUserAccount {
    return userAccountMock
  }
  
  override init() {
    needsAuth = false
    
    super.init()
  }
}
