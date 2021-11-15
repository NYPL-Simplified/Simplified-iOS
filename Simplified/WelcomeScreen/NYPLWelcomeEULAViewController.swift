import WebKit

class NYPLWelcomeEULAViewController : UIViewController {
  private static let offlineEULAPathComponent = "eula.html"

  private let onlineEULAURL: URL
  private var acceptedEULAHandler: (()->Void)
  private let webView: WKWebView
  private let activityIndicatorView: UIActivityIndicatorView
  private var attemptedLoadFromBundle = false
  
  init(onlineEULAURL: URL,
       acceptedEULAHandler: @escaping ()->Void) {
    self.onlineEULAURL = onlineEULAURL
    self.acceptedEULAHandler = acceptedEULAHandler
    self.webView = WKWebView.init()
    self.activityIndicatorView = UIActivityIndicatorView.init(style: .gray)
    super.init(nibName: nil, bundle: nil)
    self.title = NSLocalizedString("EULA", comment: "Title for User Agreement")
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK:- UIViewController

  override func viewDidLoad() {
    super.viewDidLoad()
    
    if NYPLSettings.shared.userHasAcceptedEULA {
      self.acceptedEULAHandler()
      return
    }
    
    self.navigationController?.isToolbarHidden = false
    self.view.backgroundColor = NYPLConfiguration.primaryBackgroundColor
    
    self.webView.frame = self.view.frame
    self.webView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    self.webView.backgroundColor = NYPLConfiguration.primaryBackgroundColor
    self.webView.navigationDelegate = self
    self.view.addSubview(self.webView)

    let rejectTitle = NSLocalizedString("Reject", comment: "Title for a Reject button")
    let acceptTitle = NSLocalizedString("Accept", comment: "Title for a Accept button")
    
    let rejectItem = UIBarButtonItem(title: rejectTitle,
                                     style: .plain,
                                     target: self,
                                     action: #selector(rejectedEULA))
    
    let acceptItem = UIBarButtonItem(title: acceptTitle,
                                     style: .done,
                                     target: self,
                                     action: #selector(acceptedEULA))
    if #available(iOS 12.0, *),
       UIScreen.main.traitCollection.userInterfaceStyle == .dark {
        rejectItem.tintColor = .white
        acceptItem.tintColor = NYPLConfiguration.actionColor
    }
    let middleSpacer = UIBarButtonItem.init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    self.toolbarItems = [rejectItem, middleSpacer, acceptItem]
    
    activityIndicatorView.center = self.view.center
    activityIndicatorView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(activityIndicatorView)

    loadWebView()
  }
  
  @objc func acceptedEULA() {
    NYPLSettings.shared.userHasAcceptedEULA = true
    self.acceptedEULAHandler()
  }
  
  @objc func rejectedEULA() {
    NYPLSettings.shared.userHasAcceptedEULA = false
    let alert = NYPLAlertUtils.alert(title: "NOTICE", message: "EULAHaveToAgree")
    self.present(alert, animated: true, completion: nil)
  }
  
  func loadWebView() {
    activityIndicatorView.startAnimating()
    let request = URLRequest(url: onlineEULAURL, timeoutInterval: 5.0)
    self.webView.load(request)
  }
  
  func loadWebViewFromBundle() {
    // prevent possible infinite loop
    attemptedLoadFromBundle = true

    guard let filePath = Bundle.main.path(forResource: NYPLWelcomeEULAViewController.offlineEULAPathComponent, ofType: nil) else {

      NYPLErrorLogger.logError(
        withCode: .noURL,
        summary: "Fallback EULA file not Present in Bundle",
        metadata: [
          "hardcodedFileName": NYPLWelcomeEULAViewController.offlineEULAPathComponent
        ]
      )

      // reattempt loading web view: this is safe because if it fails again
      // we will not reattempt to load from bundle anymore
      loadWebView()
      return
    }

    activityIndicatorView.startAnimating()
    let fileURL = URL(fileURLWithPath: filePath)
    webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL)
  }

  func handleError(_ error: Error) {
    activityIndicatorView.stopAnimating()
    if !attemptedLoadFromBundle {
      loadWebViewFromBundle()
    } else {
      NYPLErrorLogger.logError(
        error,
        summary: "Failed displaying EULA",
        metadata: [
          "webViewURL": webView.url?.absoluteString ?? "N/A"
      ])
    }
  }
}

// MARK:- WKNavigationDelegate

extension NYPLWelcomeEULAViewController: WKNavigationDelegate {
  func webView(_ webView: WKWebView,
               decidePolicyFor navigationAction: WKNavigationAction,
               decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    if navigationAction.request.url == onlineEULAURL {
      return decisionHandler(.allow)

    } else if navigationAction.request.url?.lastPathComponent == NYPLWelcomeEULAViewController.offlineEULAPathComponent {
      return decisionHandler(.allow)

    } else if navigationAction.navigationType == .linkActivated,
      let url = navigationAction.request.url {

      // do not open inside the app: we need to continue displaying the EULA
      if UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url)
      }
    }

    return decisionHandler(.cancel)
  }

  func webView(_ webView: WKWebView,
               decidePolicyFor navigationResponse: WKNavigationResponse,
               decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
    if let response = navigationResponse.response as? HTTPURLResponse {
      if !(200...299).contains(response.statusCode) {
        decisionHandler(.cancel)
        return
      }
    }
    decisionHandler(.allow)
  }

  // called only when the request succeeds
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    activityIndicatorView.stopAnimating()
  }

  func webView(_ webView: WKWebView,
               didFailProvisionalNavigation navigation: WKNavigation!,
               withError error: Error) {
    handleError(error)
  }

  func webView(_ webView: WKWebView,
               didFail navigation: WKNavigation!,
               withError error: Error) {
    handleError(error)
  }
}
