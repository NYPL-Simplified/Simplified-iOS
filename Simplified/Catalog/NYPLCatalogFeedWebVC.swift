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
  private static let jsBookDetailPageCallbackName = "bookDetailMsgHandler"

  #if OPENEBOOKS
  fileprivate static let librarySlug = "oe-qa"  //for Vercel app
//  fileprivate static let librarySlug = "app"  //for loading https://beta.openebooks.us/app
  #else
  fileprivate static let librarySlug = "simply-qa"  //for Vercel app
  #endif

  private var url: URL?
  var webView: WKWebView!
  let authProvider: NYPLWebAuthProvider

  @objc init(url: URL?, username: String, password: String) {
    self.url = url
    self.authProvider = NYPLWebAuthProvider(username: username,
                                            password: password)
    super.init(nibName: nil, bundle: nil)
  }

  // MARK: - UIViewController

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    let webConfig = WKWebViewConfiguration()

    // set up cookie for authentication
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

    // install webview
    webView = WKWebView(frame: .zero, configuration: webConfig)
    webView.navigationDelegate = self
    view = webView
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    if let url = url {
      // install message handler and inject JS code
      setUpJavascriptBridge()

      loadWebPage(url: url)
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }

  // MARK: - Helpers

  func setUpJavascriptBridge() {
    let contentController = webView.configuration.userContentController

    // remove all script handling to achieve idempotency
    contentController.removeAllUserScripts()
    contentController.removeScriptMessageHandler(forName: NYPLCatalogFeedWebVC.jsBookDetailPageCallbackName)

    // install ourselves as message handler, to receive callbacks from JS
    contentController.add(self, name: NYPLCatalogFeedWebVC.jsBookDetailPageCallbackName)

    // inject JS code into the web page
    let script = WKUserScript(source: bookDetailInjectableJS,
                              injectionTime: .atDocumentEnd,
                              forMainFrameOnly: false)
    contentController.addUserScript(script)
  }

  func loadWebPage(url: URL)  {
    var req = URLRequest(url: url)
    req.setValue("true", forHTTPHeaderField: NYPLCatalogFeedWebVC.webViewHeader)
    webView.load(req)
  }

  var bookDetailInjectableJS: String {
    if NYPLCatalogFeedWebVC.librarySlug == "app" {
      return """
      (function(history){
        var pushState = history.pushState;
        history.pushState = function(state) {
          //if uri format changes this will break
          if (state.as.startsWith('/\(NYPLCatalogFeedWebVC.librarySlug)/book/https')) {
            var encodedUri = state.as.split('/')[3]
            var uri = decodeURIComponent(encodedUri)

            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.\(NYPLCatalogFeedWebVC.jsBookDetailPageCallbackName)) {
              // this will call our native callback
              window.webkit.messageHandlers.\(NYPLCatalogFeedWebVC.jsBookDetailPageCallbackName).postMessage({
                "uri": uri
              });
            }
          }
          return pushState.apply(history, arguments);
        };
      })(window.history);
      """
    } else {
      return """
      (function (document) {
        function handleLinkClick(evt) {
          // determine if it's a book
          var url = new URL(evt.currentTarget.href);
          var isBookLink = url.pathname.startsWith("/\(NYPLCatalogFeedWebVC.librarySlug)/book/https");
          if (isBookLink){
            // don't navigate
            evt.preventDefault();
            var encodedUri = url.pathname.split("/")[3];
            var uri = decodeURIComponent(encodedUri);
            if (
              window.webkit &&
              window.webkit.messageHandlers &&
              window.webkit.messageHandlers.\(NYPLCatalogFeedWebVC.jsBookDetailPageCallbackName)
            ) {
              // this will call our native callback
              window.webkit
                .messageHandlers.\(NYPLCatalogFeedWebVC.jsBookDetailPageCallbackName)
                .postMessage({
                  uri: uri,
                });
            }
          }
        }
        var links = document.querySelectorAll("a");
        for (var i = 0; i < links.length; i++) {
          links[i].addEventListener("click", handleLinkClick);
        }
      })(document);
      """
    }
  }
}

// MARK: - Delegate methods

extension NYPLCatalogFeedWebVC: WKNavigationDelegate {
  func webView(_ webView: WKWebView,
               decidePolicyFor navAction: WKNavigationAction,
               decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    print("navAction.request.url=\(String(describing: navAction.request.url))")
    decisionHandler(.allow)
  }
}

extension NYPLCatalogFeedWebVC: WKScriptMessageHandler{
  func userContentController(_ userContentController: WKUserContentController,
                             didReceive message: WKScriptMessage) {

    if message.name == NYPLCatalogFeedWebVC.jsBookDetailPageCallbackName {
      guard let dict = message.body as? [String: AnyObject] else {
        Log.error(#function, "No message body compatible with the message name used to open a native Book Detail page from Javascript")
        return
      }

      guard
        let urlString = dict["uri"] as? String,
        let url = URL(string: urlString)
      else {
        Log.error(#function, "Missing uri parameter in Javascript callback used to open native Book Detail page: \(dict["uri"] as? String ?? "")")
        return
      }

      Log.info(#function, "Attempting to open native Book Detail page from a JS message with url: \(url)")

      NYPLOPDSFeedFetcher.fetchOPDSFeed(url: url,
                                        networkExecutor: NYPLNetworkExecutor.shared,
                                        shouldResetCache: false) { feed, error in
        guard
          let feed = feed,
          let opdsEntry = feed.entries?.first as? NYPLOPDSEntry
        else {
          Log.error(#function, "Unable to fetch OPDS entry for book with url: \(url)")
          return
        }

        let book = NYPLBook(entry: opdsEntry)

        NYPLMainThreadRun.asyncIfNeeded {
          let bookVC = NYPLBookDetailViewController(book: book)
          bookVC?.present(from: self)
        }
      }
    }
  }
}

// MARK: -

struct NYPLWebAuthProvider {
  let username: String
  let password: String

  var basicToken: String {
    let loginString = String(format: "%@:%@", username, password)
    let loginData = loginString.data(using: .utf8)!
    let base64LoginString = loginData.base64EncodedString()
    return "Basic \(base64LoginString)"
  }

  let cookieKey = "CPW_AUTH_COOKIE%2F\(NYPLCatalogFeedWebVC.librarySlug)"

  var cookieValue: String {
    "{\"token\":\"\(basicToken)\",\"methodType\":\"http://opds-spec.org/auth/basic\"}"
  }
}
