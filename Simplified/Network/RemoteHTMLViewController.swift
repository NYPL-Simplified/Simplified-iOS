import PureLayout
import UIKit
import WebKit

/// Similar functionality to BundledHTMLViewController, except for loading remote HTTP URL's where
/// it does not make sense in certain contexts to have bundled resources loaded.
@objcMembers final class RemoteHTMLViewController: UIViewController, WKNavigationDelegate {
  let fileURL: URL
  let failureMessage: String
  var webView: WKWebView
  var activityView: UIActivityIndicatorView!
  
  required init(URL: URL, title: String, failureMessage: String) {
    self.fileURL = URL
    self.failureMessage = failureMessage
    self.webView = WKWebView()
    
    super.init(nibName: nil, bundle: nil)
    
    self.title = title
  }
  
  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    webView.frame = self.view.frame
    webView.navigationDelegate = self
    webView.backgroundColor = NYPLConfiguration.defaultBackgroundColor
    webView.allowsBackForwardNavigationGestures = true

    view.addSubview(self.webView)
    webView.autoPinEdgesToSuperviewEdges()

    let request = URLRequest.init(url: fileURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
    webView.load(request)
    
    activityViewShouldShow(true)
  }
  
  func activityViewShouldShow(_ shouldShow: Bool) -> Void {
    if shouldShow == true {
      activityView = UIActivityIndicatorView.init(style: .gray)
      view.addSubview(activityView)
      activityView.autoCenterInSuperview()
      activityView.startAnimating()
    } else {
      activityView?.stopAnimating()
      activityView?.removeFromSuperview()
    }
  }

  func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    activityViewShouldShow(false)
    let alert = UIAlertController.init(title: NSLocalizedString(
      "Connection Failed",
      comment: "Title for alert that explains that the page could not download the information"),
                                       message: error.localizedDescription,
                                       preferredStyle: .alert)
    let action1 = UIAlertAction.init(title: NSLocalizedString("Cancel", comment: "Button that says to cancel and go back to the last screen."), style: .destructive) { (cancelAction) in
      _ = self.navigationController?.popViewController(animated: true)
    }
    let action2 = UIAlertAction.init(title: NSLocalizedString("Reload", comment: "Button that says to try again"), style: .destructive) { (reloadAction) in
      let urlRequest = URLRequest(url: self.fileURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
      webView.load(urlRequest)
    }
    
    alert.addAction(action1)
    alert.addAction(action2)
    self.present(alert, animated: true, completion: nil)
  }
  
  func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

    guard navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url else {
      decisionHandler(.allow)
      return
    }

    if UIApplication.shared.canOpenURL(url) {
      UIApplication.shared.open(url)
    }
    decisionHandler(.cancel)
  }
  
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    activityViewShouldShow(false)
  }

  func webView(_ webView: WKWebView,
               didFail navigation: WKNavigation!,
               withError error: Error) {
    activityViewShouldShow(false)
  }
}
