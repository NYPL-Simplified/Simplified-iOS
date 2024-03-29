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
                          completion: @escaping ((Bool, Error?) -> Void)) {
    
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
                      loggingContext: loggingContext,
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
                                 loggingContext: [String: Any],
                                 completion: @escaping ((Bool, Error?) -> Void)) {

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
                                  completion: { [weak self] success, error, deviceID, userID in
      // make sure to cancel the previously scheduled selector
      // from the same thread it was scheduled on
      NYPLMainThreadRun.asyncIfNeeded {
        if let self = self {
          NSObject.cancelPreviousPerformRequests(withTarget: self)
        }
      }
      
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
      
      completion(success, error)
    })

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
