//
//  NYPLCatalogFeedWebVC.swift
//  Simplified
//
//  Created by Ettore Pasquini on 1/19/22.
//  Copyright © 2022 NYPL. All rights reserved.
//

import Foundation
import UIKit
import WebKit

class NYPLCatalogFeedWebVC: UIViewController {
  private static let webViewHeader = "X-NYPL-Mobile-Webview"
  private static let defaultDomain = "simplye-web-git-oe-326-mobile-webview-nypl.vercel.app"

  private var url: URL?
  var webView: WKWebView!
  let authProvider: NYPLWebAuthProvider

  @objc init(url: URL?, username: String, password: String) {
    self.url = url
    self.authProvider = NYPLWebAuthProvider(username: username,
                                            password: password)
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    let webConfig = WKWebViewConfiguration()

    let cookie = HTTPCookie(properties: [
      .domain: url?.host ?? NYPLCatalogFeedWebVC.defaultDomain,
      .path: "",
      .name: authProvider.cookieKey,
      .value: authProvider.cookieValue,
      .secure: "TRUE",
    ])!
    if #available(iOS 11.0, *) {
      webConfig.websiteDataStore.httpCookieStore.setCookie(cookie)
    } else {
      // Fallback on earlier versions
    }
    webView = WKWebView(frame: .zero, configuration: webConfig)
    webView.navigationDelegate = self
    view = webView
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    if let url = url {
      loadWebPage(url: url)
    }
  }

  func loadWebPage(url: URL)  {
    var req = URLRequest(url: url)
    req.setValue("true", forHTTPHeaderField: NYPLCatalogFeedWebVC.webViewHeader)
    webView.load(req)
  }
}

extension NYPLCatalogFeedWebVC: WKNavigationDelegate {
  func webView(_ webView: WKWebView,
               decidePolicyFor navAction: WKNavigationAction,
               decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    print("navAction.request.url=\(String(describing: navAction.request.url))")
    decisionHandler(.allow)
  }

//  func webView(_ webView: WKWebView,
//               didReceive challenge: URLAuthenticationChallenge,
//               completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
//
//    let credsProvider = NYPLUserAccount.sharedAccount()
//    let authChallenger = NYPLBasicAuth(credentialsProvider: credsProvider)
//    authChallenger.handleChallenge(challenge, completion: completionHandler)
//  }
}


struct NYPLWebAuthProvider {
  let username: String
  let password: String

  var basicToken: String {
    let loginString = String(format: "%@:%@", username, password)
    let loginData = loginString.data(using: .utf8)!
    let base64LoginString = loginData.base64EncodedString()
    return "Basic \(base64LoginString)"
  }

  #if OPENEBOOKS
  let cookieKey = "CPW_AUTH_COOKIE%2Foe-qa"
  #else
  let cookieKey = "CPW_AUTH_COOKIE%2Fsimply-qa"
  #endif

  var cookieValue: String {
    "{\"token\":\"\(basicToken)\",\"methodType\":\"http://opds-spec.org/auth/basic\"}"
  }
}
