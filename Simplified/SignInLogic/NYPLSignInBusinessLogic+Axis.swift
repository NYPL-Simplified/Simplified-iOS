//
//  NYPLSignInBusinessLogic+Axis.swift
//  Simplified
//
//  Created by Raman Singh on 2021-04-14.
//  Copyright © 2021 NYPL. All rights reserved.
//

import Foundation

#if AXIS

extension NYPLSignInBusinessLogic {
  
  /// Perform the DRM authorization request with the given credentials
  ///
  /// - Parameters:
  ///   - username: DRM token username.
  ///   - password: DRM token password.
  ///   - loggingContext: Information to report when logging errors.
  func drmAuthorize(username: String,
                    password: String?,
                    loggingContext: [String: Any]) {
    
    let vendor = userAccount.licensor?["vendor"] as? String
    
    Log.info(#file, """
      ***DRM Auth/Activation Attempt***
      Token username: \(username)
      Token password: \(password ?? "N/A")
      VendorID: \(vendor ?? "N/A")
      """)
    
    drmAuthorizer?
      .authorize(
        withVendorID: vendor,
        username: username,
        password: password
      ) { [weak self] success, error, deviceID, userID in
        
        guard let self = self else {
          
          let error = NSError(
            domain: "NYPLSignInBusinessLogic deallocated prematurely",
            code: 418, userInfo: nil)
          
          NYPLErrorLogger.logLocalAuthFailed(error: error,
                                             library: nil,
                                             metadata: loggingContext)
        
          return
        }
        
        Log.info(#file, """
          Activation success: \(success)
          Error: \(error?.localizedDescription ?? "N/A")
          DeviceID: \(deviceID ?? "N/A")
          UserID: \(userID ?? "N/A")
          ***DRM Auth/Activation completion***
          """)
        
        var success = success
        
        if success, let userID = userID, let deviceID = deviceID {
          NYPLMainThreadRun.asyncIfNeeded {
            self.userAccount.setUserID(userID)
            self.userAccount.setDeviceID(deviceID)
          }
        } else {
          success = false
          NYPLErrorLogger.logLocalAuthFailed(error: error as NSError?,
                                             library: self.libraryAccount,
                                             metadata: loggingContext)
        }
        
        self.finalizeSignIn(forDRMAuthorization: success,
                            error: error as NSError?)
    }
  }
  
}

#endif
