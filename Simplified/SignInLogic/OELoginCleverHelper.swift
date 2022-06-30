//
//  OELoginCleverHelper.swift
//  Simplified
//
//  Created by Ettore Pasquini on 6/16/22.
//  Copyright © 2022 NYPL. All rights reserved.
//

import UIKit

class OELoginCleverHelper: NSObject {

  var signInBusinessLogic: NYPLSignInBusinessLogic!
  weak var navigationController: UINavigationController?
  var forceEditability: Bool = false
  weak var postLoginConfigurator: OEAppUIStructureConfigurating?

  init(navigationController: UINavigationController,
       postLoginConfigurator: OEAppUIStructureConfigurating?) {
    self.navigationController = navigationController
    self.postLoginConfigurator = postLoginConfigurator

    super.init()

    let accountManager = AccountsManager.shared
    self.signInBusinessLogic = NYPLSignInBusinessLogic(
      libraryAccountID: accountManager.currentAccountId!, //TODO
      libraryAccountsProvider: accountManager,
      urlSettingsProvider: NYPLSettings.shared,
      bookRegistry: NYPLBookRegistry.shared(),
      bookDownloadsRemover: NYPLMyBooksDownloadCenter.shared(),
      userAccountProvider: NYPLUserAccount.self,
      uiDelegate: self,
      drmAuthorizerAdobe: nil,
      drmAuthorizerAxis: NYPLAxisDRMAuthorizer.sharedInstance)
  }

  func startCleverFlow() {
    let cleverAuth = signInBusinessLogic.libraryAccount?.details?.auths.filter { auth in
      auth.isOauthIntermediary
    }.first

    signInBusinessLogic.selectedIDP = nil
    signInBusinessLogic.selectedAuthentication = cleverAuth
    signInBusinessLogic.logIn()
  }
}

extension OELoginCleverHelper: NYPLSignInOutBusinessLogicUIDelegate {
  func businessLogicWillSignOut(_ businessLogic: NYPLSignInBusinessLogic) {
    // unused
  }

  func businessLogic(_ logic: NYPLSignInBusinessLogic, didEncounterSignOutError error: Error?, withHTTPStatusCode httpStatusCode: Int) {
    // unused
  }

  func businessLogicDidFinishDeauthorizing(_ logic: NYPLSignInBusinessLogic) {
    // unused
  }

  var context: String {
    return "CleverHelper"
  }

  func businessLogicWillSignIn(_ signInBusinessLogic: NYPLSignInBusinessLogic) {
    // unused
  }

  func businessLogicDidCompleteSignIn(_ businessLogic: NYPLSignInBusinessLogic) {
    DispatchQueue.main.async {
      assert(businessLogic.userAccount.isSignedIn())
      Log.debug(#function, "about to set up root VC; isSignedIn=\(businessLogic.userAccount.isSignedIn())")
      self.postLoginConfigurator?.setUpRootVC(userIsSignedIn: true)
    }
  }

  func businessLogic(_ logic: NYPLSignInBusinessLogic,
                     didEncounterValidationError error: Error?,
                     userFriendlyErrorTitle title: String?,
                     andMessage serverMessage: String?) {
    let alert: UIAlertController!
    if serverMessage != nil {
      alert = NYPLAlertUtils.alert(title: title, message: serverMessage)
    } else {
      alert = NYPLAlertUtils.alert(title: title, error: error as? NSError)
    }

    self.present(alert, animated: true, completion: nil)
  }

  func dismiss(animated flag: Bool, completion: (() -> Void)?) {
    navigationController?.dismiss(animated: flag, completion: completion)
  }

  func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
    navigationController?.present(viewControllerToPresent, animated: flag, completion: completion)
  }

  // MARK: - NYPLBasicAuthCredentialsProvider

  var username: String? {
    return nil
  }

  var pin: String? {
    return nil
  }

  var requiresUserAuthentication: Bool {
    signInBusinessLogic.userAccount.requiresUserAuthentication
  }

  func hasCredentials() -> Bool {
    signInBusinessLogic.userAccount.hasCredentials()
  }

  // MARK: - NYPLOAuthTokenProvider

  var authToken: String? {
    signInBusinessLogic.userAccount.authToken
  }

  func setAuthToken(_ token: String) {
    signInBusinessLogic.userAccount.setAuthToken(token)
  }

  func hasOAuthClientCredentials() -> Bool {
    return false
  }

  var oauthTokenRefreshURL: URL? {
    signInBusinessLogic.userAccount.oauthTokenRefreshURL
  }

  // MARK: - NYPLUserAccountInputProvider

  var usernameTextField: UITextField? {
    return nil
  }

  var PINTextField: UITextField? {
    return nil
  }
}
