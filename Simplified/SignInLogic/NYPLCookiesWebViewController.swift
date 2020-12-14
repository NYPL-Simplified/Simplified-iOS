//
//  NYPLCookiesWebViewController.swift
//  SimplyE
//
//  Created by Jacek Szyja on 17/06/2020.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import UIKit
import WebKit

// WARNING: This does not work  well for iOS versions lower than 11
@objcMembers
class NYPLCookiesWebViewModel: NSObject {
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
  private static var automaticBrowserStorage: [String: NYPLCookiesWebViewController] = [:]
  var model: NYPLCookiesWebViewModel? // must be set before view loads
  private var domainCookies: [String: HTTPCookie] = [:] // (<domain><cookiename>) is a key, use for ios < 11 only
  private var rawCookies: [HTTPCookie] {
    // use for ios < 11 only
    domainCookies.map { $0.value }
  }
  private let webView = WKWebView()
  private var previousRequest: URLRequest?

  init() {
    super.init(nibName: nil, bundle: nil)

    webView.configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
  }

  init(model: NYPLCookiesWebViewModel) {
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
    assert(model != nil, "You nneed to set the model first!")

    if model?.autoPresentIfNeeded == true {
      NYPLCookiesWebViewController.automaticBrowserStorage[uuid] = self
    }

    navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Cancel", comment: ""), style: .plain, target: self, action: #selector(didSelectCancel))

    webView.navigationDelegate = self
    guard let model = model else { return }
    if !model.cookies.isEmpty {
      // if there are cookies to inject
      var cookiesLeft = model.cookies.count
      for cookie in model.cookies {
        if #available(iOS 11.0, *) {
          // inject them one by one to the cookie store
          webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie) { [model, webView] in
            cookiesLeft -= 1
            if cookiesLeft == 0 {
              webView.load(model.request)
            }
          }
        } else {
          // Fallback on earlier versions
          // add them to a local cookies dictionary stored with domain + cookie name keys
          self.domainCookies[cookie.domain + cookie.name] = cookie

          cookiesLeft -= 1
          if cookiesLeft == 0 {
            loadWebPage(request: model.request)
          }
        }
      }
    } else {
      webView.load(model.request)
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    NYPLCookiesWebViewController.automaticBrowserStorage[uuid] = nil
  }

  @objc private func didSelectCancel() {
    (navigationController?.presentingViewController ?? presentingViewController)?.dismiss(animated: true, completion: { [model] in model?.loginCancelHandler?() })
  }

  func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

    // save this request, in case a response will contain a book
    previousRequest = navigationAction.request

    // if model has some way of procesing login completion
    if let loginHandler = model?.loginCompletionHandler {
      // and login process just did complete
      if let destination = navigationAction.request.url, destination.absoluteString.hasPrefix(NYPLSettings.shared.universalLinksURL.absoluteString) {

        // cancel further webview redirections and loading
        decisionHandler(.cancel)

        if #available(iOS 11.0, *) {
          // dump all the cookies from the webview
          webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [uuid] (cookies) in
            loginHandler(destination, cookies)
            NYPLCookiesWebViewController.automaticBrowserStorage[uuid] = nil
          }
        } else {
          // use the cookies that we store in local variable
          loginHandler(destination, rawCookies)
          NYPLCookiesWebViewController.automaticBrowserStorage[uuid] = nil
        }

        return
      }
    }

    if #available(iOS 11.0, *) { } else {
      // on older iOS, cookies are injected to each request header

      // first thing, we check this request already has a custom mark added to header
      // so that we don't fall into inifinite loop of redirection handling
      let isCustomRequest = navigationAction.request.value(forHTTPHeaderField: "x-custom-header") != nil

      // other thing we need to do, is to verify if there are any cookies for the domain
      let domainCookies = rawCookies.filter { $0.domain == navigationAction.request.url?.host }

      // verify if cookie injecting is needed at all
      if !isCustomRequest && !domainCookies.isEmpty {
        // if request was not customized yet, and there are cookies to apply, do it by:

        // discarding current request
        decisionHandler(.cancel)

        // redo the same request, but after customization (injecting cookies into request header)
        loadWebPage(request: navigationAction.request)
        return
      }
    }

    decisionHandler(.allow)
  }

  /// Injects cookies into the given request.
  /// - Important: Use only on iOS < 11.
  private func loadWebPage(request: URLRequest)  {
    var mutableRequest = request

    // add a marker that we already customized this request, so that we don't fall into infinite redirections loop
    mutableRequest.setValue("true", forHTTPHeaderField: "x-custom-header")

    // get header with cookies for this request's domain
    let headers = HTTPCookie.requestHeaderFields(with: rawCookies.filter { $0.domain == mutableRequest.url?.host })
    for (name, value) in headers {
      mutableRequest.addValue(value, forHTTPHeaderField: name)
    }

    // load customized request
    webView.load(mutableRequest)
  }

  private var wasBookFound = false
  func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {

    if #available(iOS 11.0, *) { } else {
      // this block saves new cookies if any are available
      // first thing it does, is to try to obtain the header fields
      if
        let response = navigationResponse.response as? HTTPURLResponse,
        let allHttpHeaders = response.allHeaderFields as? [String: String],
        let responseUrl = response.url
      {
        // next, it parses the header trying to obtain any cookies from there
        let newCookies = HTTPCookie.cookies(withResponseHeaderFields: allHttpHeaders, for: responseUrl)

        for cookie in newCookies {
          // and finally add new cookies to the local cookies storage
          domainCookies[cookie.domain + cookie.name] = cookie
        }
      }
    }

    // if model has a way of handling a book file
    if let bookHandler = model?.bookFoundHandler {
      // get a list of supported mime types for books
      let supportedTypes = NYPLBookAcquisitionPath.supportedTypes()

      // if current response will load a supported type of book
      if let responseType = navigationResponse.response.mimeType, supportedTypes.contains(responseType) {
        // discard further loading
        decisionHandler(.cancel)
        wasBookFound = true

        if #available(iOS 11.0, *) {
          // get all the cookies, they might have changed for example in case when session expired
          webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [uuid, weak self] cookies in
            // pass the request that caused this response and new cookies to the model
            bookHandler(self?.previousRequest, cookies)
            NYPLCookiesWebViewController.automaticBrowserStorage[uuid] = nil

            // if we chose to let this webview controller present on its own, it should dismiss itself as well
            if self?.model?.autoPresentIfNeeded == true {
              (self?.navigationController?.presentingViewController ?? self?.presentingViewController)?.dismiss(animated: true, completion: nil)
            }
          }
        } else {
          // pass the request that caused this response and new cookies to the model
          bookHandler(previousRequest, rawCookies)
          NYPLCookiesWebViewController.automaticBrowserStorage[uuid] = nil
          if model?.autoPresentIfNeeded == true {
            (navigationController?.presentingViewController ?? presentingViewController)?.dismiss(animated: true, completion: nil)
          }

        }

        return
      }
    }

    // if model can handle a problem document
    if let problemHandler = model?.problemFound {
      // and problem document just happend
      if let responseType = navigationResponse.response.mimeType, responseType == "application/problem+json" || responseType == "application/api-problem+json" {

        // discard further loading
        decisionHandler(.cancel)
        let presenter = navigationController?.presentingViewController ?? presentingViewController
        if let presentingVC = presenter, model?.autoPresentIfNeeded == true {
          presentingVC.dismiss(animated: true, completion: { [uuid] in
            problemHandler(nil)
            NYPLCookiesWebViewController.automaticBrowserStorage[uuid] = nil
          })
        } else {
          // handle problem document outside
          problemHandler(nil)
          NYPLCookiesWebViewController.automaticBrowserStorage[uuid] = nil
        }

        return
      }
    }

    decisionHandler(.allow)
  }

  private var loginScreenHandlerOnceOnly = true
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {

    // when loading just finished
    // and this controller is asked to autopresent itself if needed
    if model?.autoPresentIfNeeded == true {
      // delay is needed in case IDP will want to do a redirect after initial load (from within the page)
      OperationQueue.current?.underlyingQueue?.asyncAfter(deadline: .now() + 0.5) { [weak self] in
        // once the time comes, we check if the controller still exists
        guard let self = self else { return }
        // we want to present only if webview really finished loading
        guard !self.webView.isLoading else { return }
        // and no book was found
        guard !self.wasBookFound else { return }
        // and we didn't already handled this case
        guard self.loginScreenHandlerOnceOnly else { return }
        self.loginScreenHandlerOnceOnly = false

        // we can present
        let navigationWrapper = UINavigationController(rootViewController: self)
        NYPLRootTabBarController.shared()?.safelyPresentViewController(navigationWrapper, animated: true, completion: nil)

        // and actually remove reference to self, as this controller already is added to the UI stack
        NYPLCookiesWebViewController.automaticBrowserStorage[self.uuid] = nil
      }
    }
  }
}

extension NYPLCookiesWebViewController: UIAdaptivePresentationControllerDelegate {
  func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
    model?.loginCancelHandler?()
  }
}
