import UIKit

/// Used for displaying HTML pages (and their associated resources) that are
/// bundled with an application. Any clicked links will open in an external
/// web browser, thus their content should not be part of the application.
final class BundledHTMLViewController: UIViewController {
  let fileURL: NSURL
  let webView: UIWebView
  let webViewDelegate: UIWebViewDelegate
  
  required init(fileURL: NSURL, title: String) {
    self.fileURL = fileURL
    self.webView = UIWebView.init()
    self.webViewDelegate = WebViewDelegate()
    
    super.init(nibName: nil, bundle: nil)
    
    self.title = title
  }
  
  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    self.webView.frame = self.view.bounds
    self.webView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
    self.webView.backgroundColor = UIColor.whiteColor()
    self.webView.delegate = self.webViewDelegate
    self.webView.dataDetectorTypes = .None;
    self.view.addSubview(self.webView)
  }
  
  override func viewWillAppear(animated: Bool) {
    self.webView.loadRequest(NSURLRequest.init(URL: self.fileURL))
  }
  
  private class WebViewDelegate: NSObject, UIWebViewDelegate {
    @objc func webView(
      webView: UIWebView,
      shouldStartLoadWithRequest request: NSURLRequest,
                                 navigationType: UIWebViewNavigationType) -> Bool
    {
      if navigationType == .LinkClicked {
        UIApplication.sharedApplication().openURL(request.URL!)
        return false
      }
      
      // We should not be going out to the network for anything.
      return request.URL!.scheme == "file"
    }
  }
}
