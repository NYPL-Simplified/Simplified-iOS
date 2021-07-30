//
//  NYPLAxisDRMAuthorizer.swift
//  Simplified
//
//  Created by Raman Singh on 2021-04-13.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
import NYPLAxis

#if AXIS
@objcMembers
class NYPLAxisDRMAuthorizer: NSObject, NYPLDRMAuthorizing {
  
  private let deviceInfoProvider: NYPLDeviceInfoProviding
  
  @objc static let sharedInstance = NYPLAxisDRMAuthorizer(
    deviceInfoProvider: NYPLDeviceInfoProvider())
  
  @objc
  init(deviceInfoProvider: NYPLDeviceInfoProviding) {
    self.deviceInfoProvider = deviceInfoProvider
  }
  
  /// Not applicable for Axis
  var workflowsInProgress: Bool {
    return false
  }
  
  /// We're always returning true since Axis does not deauthorize a user.
  func isUserAuthorized(_ userID: String!,
                        withDevice device: String!) -> Bool {
   return true
  }
  
  /// As of now, we're creating a deviceID which stays saved until the user uninstalls the app.
  func authorize(withVendorID vendorID: String!,
                 username: String!,
                 password: String!,
                 completion: ((Bool, Error?, String?, String?) -> Void)!) {
    
    completion(true, nil, deviceInfoProvider.deviceID, username)
  }
  
  /// There is no mechanism for deauthorizing the user in Axis. Returning succeeding completion.
  func deauthorize(withUsername username: String!,
                   password: String!,
                   userID: String!,
                   deviceID: String!,
                   completion: ((Bool, Error?) -> Void)!) {
    
    completion(true, nil)
  }
  
}
#endif
