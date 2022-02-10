//
//  NYPLSignInBusinessLogic+Adept.swift
//  Simplified
//
//  Created by Raman Singh on 2021-04-14.
//  Copyright © 2021 NYPL. All rights reserved.
//

import Foundation

#if FEATURE_DRM_CONNECTOR

extension NYPLSignInBusinessLogic {
  
  /// Extracts username and password from user profile's drm's client token and authorizes with Adept DRM
  /// - Parameters:
  ///   - profileDoc: UserProfile document from which client token is extracted
  ///   - loggingContext: Information to report when logging errors.
  func authorizeWithAdobe(userProfile profileDoc: UserProfileDocument,
                          loggingContext: [String: Any],
                          completion: @escaping ((Bool, Error?, String?, String?) -> Void)) {
    
    guard
      let drm = profileDoc.drm?.first,
      drm.vendor != nil,
      let clientToken = drm.clientToken else {

        let drm = profileDoc.drm?.first
        Log.info(#file, "\nLicensor: \(drm?.licensor ?? ["N/A": "N/A"])")
        
        NYPLErrorLogger.logError(
          withCode: .noLicensorToken,
          summary: "SignIn: no licensor token in user profile doc",
          metadata: loggingContext)
        
        finalizeSignIn(
          forDRMAuthorization: false,
          errorMessage: "No credentials were received to authorize access to books with DRM.")
        return
    }
    
    Log.info(#file, "\nLicensor: \(drm.licensor)")
    userAccount.setLicensor(drm.licensor)
    
    var licensorItems = clientToken
      .replacingOccurrences(of: "\n", with: "")
      .components(separatedBy: "|")
    
    let tokenPassword = licensorItems.last
    licensorItems.removeLast()
    let tokenUsername = (licensorItems as NSArray).componentsJoined(by: "|")
    
    drmAuthorizeAdobe(username: tokenUsername,
                      password: tokenPassword,
                      completion: completion)
    
  }
  
  /// Perform the DRM authorization request with the given credentials
  ///
  /// - Parameters:
  ///   - username: Adobe DRM token username.
  ///   - password: Adobe DRM token password. The only reason why this is
  ///   optional is because ADEPT already handles `nil` values, so we don't
  ///   have to do the same here.
  ///   - loggingContext: Information to report when logging errors.
  private func drmAuthorizeAdobe(username: String,
                                 password: String?,
                                 completion: @escaping ((Bool, Error?, String?, String?) -> Void)) {

    let vendor = userAccount.licensor?["vendor"] as? String

    Log.info(#file, """
      ***DRM Auth/Activation Attempt***
      Token username: \(username)
      Token password: \(password ?? "N/A")
      VendorID: \(vendor ?? "N/A")
      """)

    drmAuthorizerAdobe?.authorize(withVendorID: vendor,
                                  username: username,
                                  password: password,
                                  completion: completion)

    NYPLMainThreadRun.asyncIfNeeded { [weak self] in
      self?.perform(#selector(self?.dismissAfterUnexpectedDRMDelay), with: self, afterDelay: 25)
    }
  }
  
  @objc func logInIfUserAuthorized() {
    if let drmAuthorizer = drmAuthorizerAdobe,
      !drmAuthorizer.isUserAuthorized(userAccount.userID,
                                      withDevice: userAccount.deviceID) {

      if userAccount.hasBarcodeAndPIN() && !isValidatingCredentials {
        if let usernameTextField = uiDelegate?.usernameTextField,
          let PINTextField = uiDelegate?.PINTextField
        {
          usernameTextField.text = userAccount.barcode
          PINTextField.text = userAccount.PIN
        }

        logIn()
      }
    }
  }
}

#endif
