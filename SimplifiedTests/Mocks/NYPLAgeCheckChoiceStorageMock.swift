//
//  NYPLAgeCheckChoiceStorageMock.swift
//  SimplyETests
//
//  Created by Ernest Fan on 2021-03-11.
//  Copyright © 2021 NYPL. All rights reserved.
//

import Foundation
@testable import SimplyE

class NYPLAgeCheckChoiceStorageMock: NSObject, NYPLAgeCheckChoiceStorage {
  var userPresentedAgeCheck: Bool
  
  override init() {
    userPresentedAgeCheck = false
    super.init()
  }
}
