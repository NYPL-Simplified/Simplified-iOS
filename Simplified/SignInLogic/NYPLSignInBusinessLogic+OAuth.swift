//
//  NYPLSignInBusinessLogic+OAuth.swift
//  Simplified
//
//  Created by Ettore Pasquini on 10/9/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

extension NYPLSignInBusinessLogic {
  //----------------------------------------------------------------------------
  @objc func oauthLogIn() {
    // for this kind of authentication, we want to redirect user to Safari to
    // conduct the process
    guard let oauthURL = selectedAuthentication?.oauthIntermediaryUrl else {
      NYPLErrorLogger.logError(withCode: .noURL,
                               summary: "Nil OAuth intermediary URL",
                               metadata: [
                                "authMethod": selectedAuthentication?.methodDescription ?? "N/A",
                                "context": uiDelegate?.context ?? "N/A"])
      return
    }

    guard var urlComponents = URLComponents(url: oauthURL, resolvingAgainstBaseURL: true) else {
      NYPLErrorLogger.logError(withCode: .malformedURL,
                               summary: "Malformed OAuth intermediary URL",
                               metadata: [
                                "authMethod": selectedAuthentication?.methodDescription ?? "N/A",
                                "OAUth Intermediary URL": oauthURL.absoluteString,
                                "context": uiDelegate?.context ?? "N/A"])
      return
    }

    let redirectParam = URLQueryItem(
      name: "redirect_uri",
      value: universalLinksSettings.authenticationUniversalLink.absoluteString)
    urlComponents.queryItems?.append(redirectParam)

    guard let finalURL = urlComponents.url else {
      NYPLErrorLogger.logError(withCode: .malformedURL,
                               summary: "Unable to create URL for OAuth login",
                               metadata: [
                                "authMethod": selectedAuthentication?.methodDescription ?? "N/A",
                                "OAUth Intermediary URL": oauthURL.absoluteString,
                                "redirectParam": redirectParam,
                                "context": uiDelegate?.context ?? "N/A"])
      return
    }

    NotificationCenter.default
      .addObserver(self,
                   selector: #selector(handleRedirectURL(_:)),
                   name: .NYPLAppDelegateDidReceiveCleverRedirectURL,
                   object: nil)

    UIApplication.shared.open(finalURL)
  }

  //----------------------------------------------------------------------------
  private func universalLinkRedirectURLContainsPayload(_ urlStr: String) -> Bool {
    return urlStr.contains("error")
      || (urlStr.contains("access_token") && urlStr.contains("patron_info"))
  }

  //----------------------------------------------------------------------------
  @objc func handleRedirectURL(_ notification: Notification) {
    NotificationCenter.default
      .removeObserver(self, name: .NYPLAppDelegateDidReceiveCleverRedirectURL, object: nil)

    guard let url = notification.object as? URL else {
      NYPLErrorLogger.logError(withCode: .noURL,
                               summary: "Sign-in redirection error",
                               metadata: [
                                "authMethod": selectedAuthentication?.methodDescription ?? "N/A",
                                "context": uiDelegate?.context ?? "N/A"])
      return
    }

    let urlStr = url.absoluteString
    guard urlStr.hasPrefix(universalLinksSettings.authenticationUniversalLink.absoluteString),
      universalLinkRedirectURLContainsPayload(urlStr) else {

      NYPLErrorLogger.logError(withCode: .unrecognizedUniversalLink,
                               summary: "Sign-in redirection error: missing payload",
                               metadata: [
                                "loginURL": urlStr,
                                "context": uiDelegate?.context ?? "N/A"])

      uiDelegate?.displayErrorMessage(
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
      let parsedError = error.parseJSONString as? [String: String] {

      uiDelegate?.displayErrorMessage(parsedError["title"])
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
        return
    }

    uiDelegate?.authToken = authToken
    uiDelegate?.patron = parsedPatron
    uiDelegate?.validateCredentials()
  }
}
