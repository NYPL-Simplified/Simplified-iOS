//
//  NYPLDRMAuthorizingMock.swift
//  Simplified
//
//  Created by Ettore Pasquini on 10/14/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation
@testable import SimplyE

class NYPLDRMAuthorizingMock: NSObject, NYPLDRMAuthorizing {
  var workflowsInProgress = false

  func isUserAuthorized(_ userID: String!, withDevice device: String!) -> Bool {
    return true
  }

  func authorize(withVendorID vendorID: String!, username: String!, password: String!, completion: ((Bool, Error?, String?, String?) -> Void)!) {
    completion(true, nil, nil, nil)
  }

  func deauthorize(withUsername username: String!, password: String!, userID: String!, deviceID: String!, completion: ((Bool, Error?) -> Void)!) {
    completion(true, nil)
  }
}
