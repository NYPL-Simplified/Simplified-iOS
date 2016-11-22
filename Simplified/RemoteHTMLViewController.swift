import PureLayout
import UIKit
import WebKit

/// Similar functionality to BundledHTMLViewController, except for loading remote HTTP URL's where
/// it does not make sense in certain contexts to have bundled resources loaded.
final class RemoteHTMLViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {
  let fileURL: NSURL
  let failureMessage: String
  var webView: WKWebView
  var activityView: UIActivityIndicatorView!
  
  required init(fileURL: NSURL, title: String, failureMessage: String) {
    self.fileURL = fileURL
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
    
    webView.frame = self.view.frame
    webView.navigationDelegate = self
    webView.backgroundColor = UIColor.whiteColor()

    view.addSubview(self.webView)
    webView.autoPinEdgesToSuperviewEdges()

    webView.loadRequest(NSURLRequest(URL: fileURL))
    
    activityView(animated:true)
  }
  
  func activityView(animated animated: Bool) -> Void {
    if animated == true {
      activityView = UIActivityIndicatorView.init(activityIndicatorStyle: .Gray)
      activityView.center = self.view.center
      view.addSubview(activityView)
      activityView.startAnimating()
    } else {
      activityView?.stopAnimating()
      activityView?.removeFromSuperview()
    }
  }

  func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
    activityView(animated: false)
    let alert = UIAlertController.init(title: NSLocalizedString(
      "Connection Failed",
      comment: "Title for alert that explains that the page could not download the information"),
                                       message: error.localizedDescription,
                                       preferredStyle: .Alert)
    let action1 = UIAlertAction.init(title: NSLocalizedString("Cancel", comment: "Button that says to cancel and go back to the last screen."), style: .Destructive) { (cancelAction) in
      self.navigationController?.popViewControllerAnimated(true)
    }
    let action2 = UIAlertAction.init(title: NSLocalizedString("Reload", comment: "Button that says to try again"), style: .Destructive) { (reloadAction) in
      let urlRequest = NSURLRequest(URL: self.fileURL, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: 10.0)
      webView.loadRequest(urlRequest)
    }
    
    alert.addAction(action1)
    alert.addAction(action2)
    self.presentViewController(alert, animated: true, completion: nil)
  }
  
  func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
    activityView(animated: false)
  }

  
//  private class WebViewDelegate: NSObject, WKUIDelegate {
//    @objc func webView(
//      webView: UIWebView,
//      shouldStartLoadWithRequest request: NSURLRequest,
//                                 navigationType: UIWebViewNavigationType) -> Bool
//    {
//      if navigationType == .LinkClicked {
//        UIApplication.sharedApplication().openURL(request.URL!)
//        return false
//      }
//      
//      // We should not be going out to the network for anything.
//      return request.URL!.scheme == "file"
//    }
//  }
  
  
}
