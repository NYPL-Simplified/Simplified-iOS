//
//  NYPLCleverSignInHelper.swift
//  Simplified
//
//  Created by Ettore Pasquini on 6/16/22.
//  Copyright © 2022 NYPL. All rights reserved.
//

import UIKit
import SafariServices
import AuthenticationServices

class NYPLSignInCleverHelper: NSObject {

  var signInBusinessLogic: NYPLSignInBusinessLogic!
  weak var navigationController: UINavigationController?
  var forceEditability: Bool = false
  weak var postLoginConfigurator: OEAppUIStructureConfigurating?

  init(navigationController: UINavigationController,
       postLoginConfigurator: OEAppUIStructureConfigurating?) {
    self.navigationController = navigationController
    self.postLoginConfigurator = postLoginConfigurator

    let drmAuthorizerAdobe: NYPLDRMAuthorizing?
#if FEATURE_DRM_CONNECTOR
    drmAuthorizerAdobe = NYPLADEPT.sharedInstance
#else
    drmAuthorizerAdobe = nil
#endif

    let drmAuthorizerAxis: NYPLDRMAuthorizing?
#if AXIS
    drmAuthorizerAxis = NYPLAxisDRMAuthorizer.sharedInstance
#else
    drmAuthorizerAxis = nil
#endif

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
      drmAuthorizerAdobe: drmAuthorizerAdobe,
      drmAuthorizerAxis: drmAuthorizerAxis)
  }

  func startCleverFlow() {
    let cleverAuth = signInBusinessLogic.libraryAccount?.details?.auths.filter { auth in
      auth.isOauthIntermediary
    }.first

    signInBusinessLogic.selectedIDP = nil
    signInBusinessLogic.selectedAuthentication = cleverAuth
    signInBusinessLogic.logIn()
  }

  private func openSafariVC(withCleverURL cleverURL: URL) {
    Log.debug(#function, "about to push Safari VC")
    let safariVC = SFSafariViewController(url: cleverURL)
    if #available(iOS 11.0, *) {
      safariVC.dismissButtonStyle = .cancel
    }
    safariVC.delegate = self
    navigationController?.pushViewController(safariVC, animated: true)
  }

  private func openExternalBrowser(withCleverURL cleverURL: URL) {
    NYPLMainThreadRun.asyncIfNeeded {
      UIApplication.shared.open(cleverURL)
    }
  }

  private func openAuthenticatedWebSession(withCleverURL cleverURL: URL) {
    guard #available(iOS 12.0, *) else {
      return
    }

    let webSession = ASWebAuthenticationSession(url: cleverURL,
                                                callbackURLScheme: "https") { url, error in
      let notif = Notification(name: .NYPLAppDelegateDidReceiveCleverRedirectURL,
                               object: url)
      self.signInBusinessLogic.handleRedirectURL(notif)
    }
    if #available(iOS 13.0, *) {
      webSession.presentationContextProvider = self
      webSession.prefersEphemeralWebBrowserSession = true
    }

    if !webSession.start() {
      print("failed to start websession")
    }
  }
}

extension NYPLSignInCleverHelper: ASWebAuthenticationPresentationContextProviding {
  @available(iOS 12.0, *)
  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
      return window
    } else {
      return ASPresentationAnchor()
    }
  }
}

extension NYPLSignInCleverHelper: NYPLSignInOutBusinessLogicUIDelegate {
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
    //TODO: OE-514 cleanup
    guard let cleverURL = signInBusinessLogic.oauthIntermediaryURL() else {
      return
    }

    // "https://circulation.openebooks.us/USOEI/oauth_authenticate?provider=Clever&redirect_uri=https://librarysimplified.org/callbacks/OpenEbooks"
    if #available(iOS 12.0, *) {
      openAuthenticatedWebSession(withCleverURL: cleverURL)
    } else {
      openSafariVC(withCleverURL: cleverURL)
    }
  }

  func businessLogicDidCompleteSignIn(_ businessLogic: NYPLSignInBusinessLogic) {
    DispatchQueue.main.async {
      assert(businessLogic.userAccount.isSignedIn())
      Log.debug(#function, "about to set up root VC; isSignedIn=\(businessLogic.userAccount.isSignedIn())")
      self.postLoginConfigurator?.setUpRootVC()
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

// MARK: -

//TODO: OE-514 cleanup
extension NYPLSignInCleverHelper: SFSafariViewControllerDelegate {
  func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
    navigationController?.popToRootViewController(animated: true)
  }
}
