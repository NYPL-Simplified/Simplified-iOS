import UIKit

/// Used for displaying HTML pages (and their associated resources) that are
/// bundled with an application. Any clicked links will open in an external
/// web browser, thus their content should not be part of the application.
final class BundledHTMLViewController: UIViewController {
  let fileURL: URL
  let webView: UIWebView
  let webViewDelegate: UIWebViewDelegate
  
  required init(fileURL: URL, title: String) {
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
    self.webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    self.webView.backgroundColor = UIColor.white
    self.webView.delegate = self.webViewDelegate
    self.webView.dataDetectorTypes = UIDataDetectorTypes();
    self.view.addSubview(self.webView)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    self.webView.loadRequest(URLRequest.init(url: self.fileURL))
  }
  
  fileprivate class WebViewDelegate: NSObject, UIWebViewDelegate {
    @objc func webView(
      _ webView: UIWebView,
      shouldStartLoadWith request: URLRequest,
                                 navigationType: UIWebView.NavigationType) -> Bool
    {
      if navigationType == .linkClicked {
        UIApplication.shared.openURL(request.url!)
        return false
      }
      
      // We should not be going out to the network for anything.
      return request.url!.scheme == "file"
    }
  }
}
