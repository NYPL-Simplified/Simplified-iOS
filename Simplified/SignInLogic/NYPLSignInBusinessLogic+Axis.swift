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
  func drmAuthorizeAxis(username: String,
                        password: String?,
                        loggingContext: [String: Any]) {
    
    let vendor = userAccount.licensor?["vendor"] as? String
    
    Log.info(#file, """
      ***DRM Auth/Activation Attempt***
      Token username: \(username)
      Token password: \(password ?? "N/A")
      VendorID: \(vendor ?? "N/A")
      """)
    
    drmAuthorizerAxis?
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
        
        if success, userID != nil, deviceID != nil {
          Log.info(#function, "Axis authorized successfully")
//          NYPLMainThreadRun.asyncIfNeeded {
//            //TODO: IOS-336
//            self.userAccount.setUserID(userID)
//            self.userAccount.setDeviceID(deviceID)
//          }
        } else {
          success = false
          NYPLErrorLogger.logLocalAuthFailed(error: error as NSError?,
                                             library: self.libraryAccount,
                                             metadata: loggingContext)
        }

        // when we are building with Axis AND Adobe DRM, the
        // `drmAuthorizeAxis(username:password:loggingContext:)` implementation
        // always end up reaching this point (unless `self` went away, in which
        // case everything is moot). Therefore, since we will need to call
        // `finalizeSignIn(forDRMAuthorization:error:)` for the Adobe case,
        // we can just skip it here.
#if !FEATURE_DRM_CONNECTOR
        self.finalizeSignIn(forDRMAuthorization: success,
                            error: error as NSError?)
#endif
    }
  }
  
}

#endif
