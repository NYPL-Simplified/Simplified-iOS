//
//  NYPLCookiesWebViewController.swift
//  SimplyE
//
//  Created by Jacek Szyja on 17/06/2020.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import UIKit
import WebKit

@objcMembers
class CookiesWebViewModel: NSObject {
  let cookies: [HTTPCookie]
  let request: URLRequest
  let loginCompletionHandler: ((URL, [HTTPCookie]) -> Void)?
  let loginCancelHandler: (() -> Void)?
  let bookFoundHandler: ((URLRequest?, [HTTPCookie]) -> Void)?
  let problemFound: (((NYPLProblemDocument?)) -> Void)?
  let autoPresentIfNeeded: Bool

  init(cookies: [HTTPCookie], request: URLRequest, loginCompletionHandler: ((URL, [HTTPCookie]) -> Void)?, loginCancelHandler: (() -> Void)?, bookFoundHandler: ((URLRequest?, [HTTPCookie]) -> Void)?, problemFoundHandler: ((NYPLProblemDocument?) -> Void)?, autoPresentIfNeeded: Bool = false) {
    self.cookies = cookies
    self.request = request
    self.loginCompletionHandler = loginCompletionHandler
    self.loginCancelHandler = loginCancelHandler
    self.bookFoundHandler = bookFoundHandler
    self.problemFound = problemFoundHandler
    self.autoPresentIfNeeded = autoPresentIfNeeded
    super.init()
  }
}

@objcMembers
class NYPLCookiesWebViewController: UIViewController, WKNavigationDelegate {
  private let uuid: String = UUID().uuidString
  private static var automaticBrowserStroage: [String: NYPLCookiesWebViewController] = [:]
  var model: CookiesWebViewModel! // must be set before view loads
  private var domainCookies: [String: [HTTPCookie]] = [:]
  private let webView = WKWebView()
  private var previousRequest: URLRequest?

  init() {
    super.init(nibName: nil, bundle: nil)
    webView.configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
  }

  init(model: CookiesWebViewModel) {
    self.model = model
    super.init(nibName: nil, bundle: nil)

    webView.configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    view = webView
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    if model.autoPresentIfNeeded {
      NYPLCookiesWebViewController.automaticBrowserStroage[uuid] = self
    }

//    if #available(iOS 13.0, *) {
//      // iOS 13 brings new page like presentation for modals, this prevents the interactive dismiss gesture
//      isModalInPresentation = true
//    }

    navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Cancel", comment: ""), style: .plain, target: self, action: #selector(didSelectCancel))

    webView.navigationDelegate = self
    if !model.cookies.isEmpty {
      var cookiesLeft = model.cookies.count
      for cookie in model.cookies {
        if #available(iOS 11.0, *) {
          webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie) { [model, webView] in
            cookiesLeft -= 1
            if cookiesLeft == 0, let request = model?.request {
              webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { (cookies) in
                print("szyjson loaded \(cookies)")
              }
              webView.load(request)
            }
          }
        } else {
          // Fallback on earlier versions
          // load cookies in old ios
        }
      }
    } else {
      webView.load(model.request)
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    NYPLCookiesWebViewController.automaticBrowserStroage[uuid] = nil
  }

  @objc private func didSelectCancel() {
    (navigationController?.presentingViewController ?? presentingViewController)?.dismiss(animated: true, completion: { [model] in model?.loginCancelHandler?() })
  }

  func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

    previousRequest = navigationAction.request

    if let loginHandler = model.loginCompletionHandler {
      // if want to receive a login callback
      if #available(iOS 11.0, *) {
        if let destination = navigationAction.request.url, destination.absoluteString.hasPrefix("https://skyneck.pl/login") {
          decisionHandler(.cancel)

          webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [model, weak self] (cookies) in
            print("szyjson login \(cookies)")
            loginHandler(destination, cookies)
            NYPLCookiesWebViewController.automaticBrowserStroage[self?.uuid ?? ""] = nil
          }

        } else {
          decisionHandler(.allow)
        }
      } else {
        if let destination = navigationAction.request.url?.absoluteString {
          if destination.hasPrefix("https://skyneck.pl/login") {
          }
        }

        decisionHandler(.allow)
      }
    } else {
      decisionHandler(.allow)
    }
  }

  private var wasBookFound = false
  func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {

    if let bookHandler = model.bookFoundHandler {
      // if want to receive a handle when book is found
      let supportedTypes = NYPLBookAcquisitionPath.supportedTypes()
      
      if let responseType = navigationResponse.response.mimeType, supportedTypes.contains(responseType) {
        wasBookFound = true

        if #available(iOS 11.0, *) {
          decisionHandler(.cancel)
          webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            bookHandler(self?.previousRequest, cookies)
            NYPLCookiesWebViewController.automaticBrowserStroage[self?.uuid ?? ""] = nil
            if self?.model.autoPresentIfNeeded == true {
              (self?.navigationController?.presentingViewController ?? self?.presentingViewController)?.dismiss(animated: true, completion: nil)
            }
          }
        } else {
          decisionHandler(.allow)
        }

        return
      }
    }

    if let problemHandler = model.problemFound {
      if let responseType = navigationResponse.response.mimeType, responseType == "application/problem+json" || responseType == "application/api-problem+json" {

        decisionHandler(.cancel)
        let presenter = navigationController?.presentingViewController ?? presentingViewController
        if let presentingVC = presenter, model.autoPresentIfNeeded {
          presentingVC.dismiss(animated: true, completion: { [uuid] in
            problemHandler(nil)
            NYPLCookiesWebViewController.automaticBrowserStroage[uuid] = nil
          })
        } else {
          problemHandler(nil)
          NYPLCookiesWebViewController.automaticBrowserStroage[uuid] = nil
        }

        return
      }
    }

    decisionHandler(.allow)
  }

  private var loginScreenHandlerOnceOnly = true
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {

    if model.autoPresentIfNeeded {
      // delay is needed in case IDP will want to do a redirect after initial load (from within the page)
      OperationQueue.current?.underlyingQueue?.asyncAfter(deadline: .now() + 0.5) { [weak self] in
        guard let self = self else { return }
        guard !self.webView.isLoading else { return }
        guard !self.wasBookFound else { return }
        guard self.loginScreenHandlerOnceOnly else { return }
        self.loginScreenHandlerOnceOnly = false

        let navigationWrapper = UINavigationController(rootViewController: self)
        NYPLRootTabBarController.shared()?.safelyPresentViewController(navigationWrapper, animated: true, completion: nil)
        NYPLCookiesWebViewController.automaticBrowserStroage[self.uuid] = nil
      }
    }
  }
}

extension NYPLCookiesWebViewController: UIAdaptivePresentationControllerDelegate {
  func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
    model?.loginCancelHandler?()
  }
}
