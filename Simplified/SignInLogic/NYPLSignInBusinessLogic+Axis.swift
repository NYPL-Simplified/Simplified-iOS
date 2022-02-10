//
//  NYPLSignInBusinessLogic+Axis.swift
//  Simplified
//
//  Created by Raman Singh on 2021-04-14.
//  Copyright © 2021 NYPL. All rights reserved.
//

import Foundation
import NYPLCardCreator

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
                        completion: @escaping ((Bool, Error?, String?, String?) -> Void)) {
    
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
                                 completion: completion)
  }
  
}

#endif
