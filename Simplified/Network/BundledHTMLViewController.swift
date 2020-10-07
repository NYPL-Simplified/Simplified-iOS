import UIKit
import WebKit

/// Used for displaying HTML pages (and their associated resources) that are
/// bundled with an application. Any clicked links will open in an external
/// web browser, thus their content should not be part of the application.
@objcMembers final class BundledHTMLViewController: UIViewController {
  let fileURL: URL
  let webView: WKWebView
  let webViewDelegate: WKNavigationDelegate
  
  required init(fileURL: URL, title: String) {
    self.fileURL = fileURL
    if #available(iOS 10.0, *) {
      let config = WKWebViewConfiguration()
      config.dataDetectorTypes = WKDataDetectorTypes()
      self.webView = WKWebView(frame: .zero, configuration: config)
    } else {
      self.webView = WKWebView()
    }
    self.webViewDelegate = WebViewDelegate()
    super.init(nibName: nil, bundle: nil)
    self.title = title
  }
  
  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    self.webView.navigationDelegate = nil
    self.webView.stopLoading()
  }
  
  override func viewDidLoad() {
    self.webView.frame = self.view.bounds
    self.webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    self.webView.backgroundColor = UIColor.white
    self.webView.navigationDelegate = self.webViewDelegate
    self.view.addSubview(self.webView)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    self.webView.load(URLRequest(url: self.fileURL))
  }
  
  fileprivate class WebViewDelegate: NSObject, WKNavigationDelegate
  {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void)
    {
      if navigationAction.navigationType == .linkActivated,
        let url = navigationAction.request.url {
        if !UIApplication.shared.canOpenURL(url) {
          decisionHandler(.cancel)
        } else {
          if #available(iOS 10.0, *) {
            UIApplication.shared.open(url)
          } else {
            UIApplication.shared.openURL(url)
          }
          decisionHandler(.cancel)
        }
      } else {
        decisionHandler(.allow)
      }
    }
  }
}
