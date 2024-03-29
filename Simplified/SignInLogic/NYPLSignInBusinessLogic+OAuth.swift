//
//  NYPLSignInBusinessLogic+OAuth.swift
//  Simplified
//
//  Created by Ettore Pasquini on 10/9/20.
//  Copyright © 2020 NYPL. All rights reserved.
//

import Foundation

extension NYPLSignInBusinessLogic {
  //----------------------------------------------------------------------------
  func oauthIntermediaryURL() -> URL? {
    // for this kind of authentication, we want to redirect user to Safari to
    // conduct the process
    guard let oauthURL = selectedAuthentication?.oauthIntermediaryUrl else {
      NYPLErrorLogger.logError(withCode: .noURL,
                               summary: "Nil OAuth intermediary URL",
                               metadata: [
                                "authMethod": selectedAuthentication?.methodDescription ?? "N/A",
                                "context": uiDelegate?.context ?? "N/A"])
      return nil
    }

    guard var urlComponents = URLComponents(url: oauthURL, resolvingAgainstBaseURL: true) else {
      NYPLErrorLogger.logError(withCode: .malformedURL,
                               summary: "Malformed OAuth intermediary URL",
                               metadata: [
                                "authMethod": selectedAuthentication?.methodDescription ?? "N/A",
                                "OAUth Intermediary URL": oauthURL.absoluteString,
                                "context": uiDelegate?.context ?? "N/A"])
      return nil
    }

    let redirectParam = URLQueryItem(
      name: "redirect_uri",
      value: urlSettingsProvider.universalLinksURL.absoluteString)
    urlComponents.queryItems?.append(redirectParam)

    guard let finalURL = urlComponents.url else {
      NYPLErrorLogger.logError(withCode: .malformedURL,
                               summary: "Unable to create URL for OAuth login",
                               metadata: [
                                "authMethod": selectedAuthentication?.methodDescription ?? "N/A",
                                "OAUth Intermediary URL": oauthURL.absoluteString,
                                "redirectParam": redirectParam,
                                "context": uiDelegate?.context ?? "N/A"])
      return nil
    }

    return finalURL
  }

  func oauthIntermediaryLogIn() {
    guard let finalURL = oauthIntermediaryURL() else {
      return
    }

    Log.debug(#function, "setting up observer for redirect URL")
    NotificationCenter.default
      .addObserver(self,
                   selector: #selector(handleRedirectURL(_:)),
                   name: .NYPLAppDelegateDidReceiveCleverRedirectURL,
                   object: nil)

    NYPLMainThreadRun.asyncIfNeeded {
      UIApplication.shared.open(finalURL)
    }
  }

  //----------------------------------------------------------------------------
  private func universalLinkRedirectURLContainsPayload(_ urlStr: String) -> Bool {
    return urlStr.contains("error")
      || (urlStr.contains("access_token") && urlStr.contains("patron_info"))
  }

  //----------------------------------------------------------------------------
  
  // As per Apple Developer Documentation, selector for NSNotification must have
  // one and only one argument (an instance of NSNotification).
  // See https://developer.apple.com/documentation/foundation/nsnotificationcenter/1415360-addobserver
  // for more information.
  @objc func handleRedirectURL(_ notification: Notification) {
    self.handleRedirectURL(notification, completion: nil)
  }
  
  // this is used by both Clever and SAML authentication
  @objc func handleRedirectURL(_ notification: Notification, completion: ((_ error: Error?, _ errorTitle: String?, _ errorMessage: String?)->())?) {
    NotificationCenter.default
      .removeObserver(self, name: .NYPLAppDelegateDidReceiveCleverRedirectURL, object: nil)

    Log.debug(#function, "Received OAuth redirect with object \(String(describing: notification.object))")
    guard let url = notification.object as? URL else {
      NYPLErrorLogger.logError(withCode: .noURL,
                               summary: "Sign-in redirection error",
                               metadata: [
                                "authMethod": selectedAuthentication?.methodDescription ?? "N/A",
                                "context": uiDelegate?.context ?? "N/A"])
      completion?(nil, nil, nil)
      return
    }

    let urlStr = url.absoluteString
    guard urlStr.hasPrefix(urlSettingsProvider.universalLinksURL.absoluteString),
      universalLinkRedirectURLContainsPayload(urlStr) else {

        NYPLErrorLogger.logError(withCode: .unrecognizedUniversalLink,
                                 summary: "Sign-in redirection error: missing payload",
                                 metadata: [
                                  "loginURL": urlStr,
                                  "context": uiDelegate?.context ?? "N/A"])
        completion?(nil,
                   NSLocalizedString("SettingsAccountViewControllerLoginFailed", comment: "Title for login error alert"),
                   NSLocalizedString("An error occurred during the authentication process",
                                     comment: "Generic error message while handling sign-in redirection during authentication"))
        return
    }

    var kvpairs = [String: String]()
    // Oauth method provides the auth token as a fragment while SAML as a
    // query parameter
    guard let payload = { url.fragment ?? url.query }() else {
      NYPLErrorLogger.logError(withCode: .unrecognizedUniversalLink,
                               summary: "Sign-in redirection error: payload not in fragment nor query params",
                               metadata: [
                                "loginURL": urlStr,
                                "context": uiDelegate?.context ?? "N/A"])
      completion?(nil, nil, nil)
      return
    }

    for param in payload.components(separatedBy: "&") {
      let elts = param.components(separatedBy: "=")
      guard elts.count >= 2, let key = elts.first, let value = elts.last else {
        continue
      }
      kvpairs[key] = value
    }

    if
      let rawError = kvpairs["error"],
      let error = rawError.replacingOccurrences(of: "+", with: " ").removingPercentEncoding,
      let parsedError = error.parseJSONString as? [String: Any] {

      completion?(nil,
                 NSLocalizedString("SettingsAccountViewControllerLoginFailed", comment: "Title for login error alert"),
                 parsedError["title"] as? String)
      return
    }

    guard
      let authToken = kvpairs["access_token"],
      let patronInfo = kvpairs["patron_info"],
      let patron = patronInfo.replacingOccurrences(of: "+", with: " ").removingPercentEncoding,
      let parsedPatron = patron.parseJSONString as? [String: Any] else {

        NYPLErrorLogger.logError(withCode: .authDataParseFail,
                                 summary: "Sign-in redirection error: Unable to parse auth info",
                                 metadata: [
                                  "payloadDictionary": kvpairs,
                                  "redirectURL": url,
                                  "context": uiDelegate?.context ?? "N/A"])
        completion?(nil, nil, nil)
        return
    }

    self.authToken = authToken
    self.patron = parsedPatron
    validateCredentials()
    completion?(nil, nil, nil)
  }
}
