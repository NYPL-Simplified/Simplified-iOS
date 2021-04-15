//
//  NYPLAxisDRMAuthorizer.swift
//  Simplified
//
//  Created by Raman Singh on 2021-04-13.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

#if AXIS

@objc protocol NYPLDeviceInfoProviding {
  var deviceID: String { get }
  var clientIP: String { get }
}

@objcMembers
class NYPLAxisDRMAuthorizer: NSObject, NYPLDRMAuthorizing, NYPLDeviceInfoProviding {
  
  static private let deviceIDKey = "NYPLAxisDRMAuthorizerKey"
  
  static let sharedInstance = NYPLAxisDRMAuthorizer()
  
  // MARK: - NYPLDeviceInfoProviding
  
  /// Device IP address is only needed when generating a url for downloading license. Generating actual
  /// device IP address would be more costly and would provide a result no different than what the hard
  /// coded IP address already provides. Also, this is consistent with what Android is doing.
  let clientIP = "192.168.1.254"
  
  var deviceID: String {
    if
      let id = UserDefaults.standard.string(forKey: NYPLAxisDRMAuthorizer.deviceIDKey) {
      return id
    }
    
    let id = UUID().uuidString
    UserDefaults.standard.set(id, forKey: NYPLAxisDRMAuthorizer.deviceIDKey)
    return id
  }
  
  // MARK: - NYPLDRMAuthorizing
  
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
    
    completion(true, nil, deviceID, username)
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
