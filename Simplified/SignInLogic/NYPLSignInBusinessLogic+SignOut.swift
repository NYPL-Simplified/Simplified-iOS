//
//  NYPLSignInBusinessLogic+SignOut.swift
//  Simplified
//
//  Created by Ettore Pasquini on 11/3/20.
//  Copyright © 2020 NYPL. All rights reserved.
//

import Foundation

extension NYPLSignInBusinessLogic {

  /// Main entry point for logging a user out.
  ///
  /// - Important: Requires to be called from the main thread.
  func performLogOut() {
    #if FEATURE_DRM_CONNECTOR

    uiDelegate?.businessLogicWillSignOut(self)

    // we need to make this request (which is identical to the sign-in request)
    // because in order for the Adobe deactivation to be successful, it has
    // to use a fresh Adobe token provided by the CM, since it may have expired.
    // These tokens are very short lived (1 hour).
    guard let request = self.makeRequest(for: .signOut, context: "Sign Out") else {
      // no need to log since makeRequest(for:) does log already
      return
    }

    let barcode = userAccount.barcode
    networker.executeRequest(request) { [weak self] result in
      switch result {
      case .success(let data, let response):
        self?.processLogOut(data: data,
                            response: response,
                            for: request,
                            barcode: barcode)
      case .failure(let errorWithProblemDoc, let response):
        self?.processLogOutError(errorWithProblemDoc,
                                 response: response,
                                 for: request,
                                 barcode: barcode)
      }
    }

    #else
    if self.bookRegistry.syncing {
      let alert = NYPLAlertUtils.alert(
        title: "SettingsAccountViewControllerCannotLogOutTitle",
        message: "SettingsAccountViewControllerCannotLogOutMessage")
      uiDelegate?.present(alert, animated: true, completion: nil)
    } else {
      completeLogOutProcess()
    }
    #endif
  }

  #if FEATURE_DRM_CONNECTOR
  private func processLogOut(data: Data,
                             response: URLResponse?,
                             for request: URLRequest,
                             barcode: String?) {
    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

    let profileDoc: UserProfileDocument
    do {
      profileDoc = try UserProfileDocument.fromData(data)
    } catch {
      Log.error(#file, "Unable to parse user profile at sign out (HTTP \(statusCode): Adobe device deauthorization won't be possible.")
      NYPLErrorLogger.logUserProfileDocumentAuthError(
        error as NSError,
        summary: "SignOut: unable to parse user profile doc",
        barcode: barcode,
        metadata: [
          "Request": request.loggableString,
          NSError.httpResponseKey: response ?? "N/A",
          "HTTP status code": statusCode
      ])
      self.uiDelegate?.businessLogic(self,
                                     didEncounterSignOutError: error,
                                     withHTTPStatusCode: statusCode)
      return
    }

    if let drm = profileDoc.drm?.first,
      let clientToken = drm.clientToken, drm.vendor != nil {

      // Set the fresh Adobe token info into the user account so that the
      // following `deauthorizeDevice` call can use it.
      self.userAccount.setLicensor(drm.licensor)
      Log.info(#file, "\nLicensory token updated to \(clientToken) for adobe user ID \(self.userAccount.userID ?? "N/A")")
    } else {
      Log.error(#file, "\nLicensor token invalid: \(profileDoc.toJson())")
    }

    self.deauthorizeDevice()

    #if OPENEBOOKS
    self.urlSettingsProvider.accountMainFeedURL = nil
    #endif
  }

  private func processLogOutError(_ errorWithProblemDoc: NYPLUserFriendlyError,
                                  response: URLResponse?,
                                  for request: URLRequest,
                                  barcode: String?) {
    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

    if statusCode == 401 {
      self.deauthorizeDevice()
    }

    NYPLErrorLogger.logNetworkError(
      errorWithProblemDoc,
      summary: "SignOut: token refresh failed",
      request: request,
      response: response,
      metadata: [
        "AuthMethod": self.selectedAuthentication?.methodDescription ?? "N/A",
        "Hashed barcode": barcode?.md5hex() ?? "N/A",
        "HTTP status code": statusCode])

    self.uiDelegate?.businessLogic(self,
                                   didEncounterSignOutError: errorWithProblemDoc,
                                   withHTTPStatusCode: statusCode)
  }
  #endif
  
  private func completeLogOutProcess() {
    bookDownloadsCenter.reset(libraryAccountID)
    bookRegistry.reset(libraryAccountID)
    userAccount.removeAll()
    selectedIDP = nil
    uiDelegate?.businessLogicDidFinishDeauthorizing(self)
  }

  #if FEATURE_DRM_CONNECTOR
  private func deauthorizeDevice() {
    guard let licensor = userAccount.licensor else {
      Log.warn(#file, "No Licensor available to deauthorize device. Will remove user credentials anyway.")
      NYPLErrorLogger.logInvalidLicensor(withAccountID: libraryAccountID)
      completeLogOutProcess()
      return
    }

    var licensorItems = (licensor["clientToken"] as? String)?
      .replacingOccurrences(of: "\n", with: "")
      .components(separatedBy: "|")
    let tokenPassword = licensorItems?.last
    licensorItems?.removeLast()
    let tokenUsername = licensorItems?.joined(separator: "|")
    let adobeUserID = userAccount.userID
    let adobeDeviceID = userAccount.deviceID

    Log.info(#file, """
    ***DRM Deactivation Attempt***
    Licensor: \(licensor)
    Token Username: \(tokenUsername ?? "N/A")
    Token Password: \(tokenPassword ?? "N/A")
    AdobeUserID: \(adobeUserID ?? "N/A")
    AdobeDeviceID: \(adobeDeviceID ?? "N/A")
    """)

    drmAuthorizerAdobe?.deauthorize(
      withUsername: tokenUsername,
      password: tokenPassword,
      userID: adobeUserID,
      deviceID: adobeDeviceID) { [weak self] success, error in
        if success {
          Log.info(#file, "*** Successful DRM Deactivation ***")
        } else {
          // Even though we failed, let the user continue to log out.
          // The most likely reason is a user changing their PIN.
          NYPLErrorLogger.logError(error,
                                   summary: "User lost an activation on signout: ADEPT error",
                                   metadata: [
                                    "AdobeUserID": adobeUserID ?? "N/A",
                                    "DeviceID": adobeDeviceID ?? "N/A",
                                    "Licensor": licensor,
                                    "AdobeTokenUsername": tokenUsername ?? "N/A",
                                    "AdobeTokenPassword": tokenPassword ?? "N/A"])
        }

        self?.completeLogOutProcess()
    }
  }
  #endif
}
