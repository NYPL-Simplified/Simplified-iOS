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
                        loggingContext: [String: Any],
                        completion: @escaping ((Bool, Error?) -> Void)) {
    
    let vendor = userAccount.licensor?["vendor"] as? String
    
    Log.info(#file, """
      ***DRM Auth/Activation Attempt***
      Token username: \(username)
      Token password: \(password ?? "N/A")
      VendorID: \(vendor ?? "N/A")
      """)
    
    drmAuthorizerAxis?.authorize(withVendorID: vendor,
                                 username: username,
                                 password: password,
                                 completion: { [weak self] success, error, deviceID, userID in
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

      let success = success && userID != nil && deviceID != nil

      if !success {
        NYPLErrorLogger.logLocalAuthFailed(error: error as NSError?,
                                           library: self.libraryAccount,
                                           metadata: loggingContext)
      }

      completion(success, error)
    })
  }
  
}

#endif
