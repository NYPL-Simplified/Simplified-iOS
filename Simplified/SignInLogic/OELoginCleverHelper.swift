//
//  OELoginCleverHelper.swift
//  Simplified
//
//  Created by Ettore Pasquini on 6/16/22.
//  Copyright © 2022 NYPL. All rights reserved.
//

import UIKit

protocol OECleverUIDelegate: NSObject {
  var navigationController: UINavigationController? { get }
  func cleverHelperWillSignIn(_ helper: OELoginCleverHelper)
  func cleverHelperDidFinish(_ helper: OELoginCleverHelper, error: Error?)
}

class OELoginCleverHelper: NSObject {

  private(set) var signInBusinessLogic: NYPLSignInBusinessLogic!
  var forceEditability: Bool = false
  private weak var postLoginConfigurator: OEAppUIStructureConfigurating?
  weak var uiDelegate: OECleverUIDelegate?

  init(libraryAccount: Account,
       uiDelegate: OECleverUIDelegate?,
       postLoginConfigurator: OEAppUIStructureConfigurating?) {
    self.uiDelegate = uiDelegate
    self.postLoginConfigurator = postLoginConfigurator

    super.init()

    self.signInBusinessLogic = NYPLSignInBusinessLogic(
      libraryAccountID: libraryAccount.uuid,
      libraryAccountsProvider: AccountsManager.shared,
      urlSettingsProvider: NYPLSettings.shared,
      bookRegistry: NYPLBookRegistry.shared(),
      bookDownloadsRemover: NYPLMyBooksDownloadCenter.shared(),
      userAccountProvider: NYPLUserAccount.self,
      uiDelegate: self,
      drmAuthorizerAdobe: nil,
      drmAuthorizerAxis: NYPLAxisDRMAuthorizer.sharedInstance)
  }

  func startCleverFlow() {
    uiDelegate?.cleverHelperWillSignIn(self)
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

  func businessLogicDidSignIn(_ businessLogic: NYPLSignInBusinessLogic) {
    DispatchQueue.main.async {
      assert(businessLogic.userAccount.isSignedIn())
      Log.debug(#function, "about to set up root VC; isSignedIn=\(businessLogic.userAccount.isSignedIn())")
      self.uiDelegate?.cleverHelperDidFinish(self, error: nil)
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

    self.present(alert, animated: true) { [weak self] in
      guard let self = self else { return }
      self.uiDelegate?.cleverHelperDidFinish(self, error: error)
    }
  }

  func dismiss(animated flag: Bool, completion: (() -> Void)?) {
    uiDelegate?.navigationController?.dismiss(animated: flag,
                                              completion: completion)
  }

  func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
    uiDelegate?.navigationController?.present(viewControllerToPresent,
                                              animated: flag,
                                              completion: completion)
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

  // MARK: - NYPLOAuthTokenSource

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
