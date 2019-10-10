class OEEULAViewController : UIViewController, UIWebViewDelegate {
  static let onlineEULAPath = "http://www.librarysimplified.org/openebookseula.html"
  static let offlineEULAPathComponent = "eula.html"
  
  private var handler: (()->Void)
  private let webView: UIWebView
  private let activityIndicatorView: UIActivityIndicatorView
  
  
  init(completionHandler: @escaping ()->Void) {
    self.handler = completionHandler
    self.webView = UIWebView.init()
    self.activityIndicatorView = UIActivityIndicatorView.init(style: .gray)
    super.init(nibName: nil, bundle: nil)
    self.title = OEUtils.LocalizedString("EULA")
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: UIViewController
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if OESettings.oeShared.userHasAcceptedEULA {
      self.handler()
      return
    }
    
    self.navigationController?.isToolbarHidden = false
    self.view.backgroundColor = OEConfiguration.shared.backgroundColor
    
    self.webView.frame = self.view.frame
    self.webView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    self.webView.backgroundColor = OEConfiguration.shared.backgroundColor
    self.webView.delegate = self
    self.view.addSubview(self.webView)
    self.loadWebView()
    
    let rejectButton = UIButton.init(type: .system)
    rejectButton.titleLabel?.font = UIFont.systemFont(ofSize: 21)
    let rejectTitle = OEUtils.LocalizedString("Reject")
    
    let acceptButton = UIButton.init(type: .system)
    acceptButton.titleLabel?.font = UIFont.systemFont(ofSize: 21)
    let acceptTitle = OEUtils.LocalizedString("Accept")
    
    let rejectItem = UIBarButtonItem.init(title: rejectTitle, style: .plain, target: self, action: #selector(rejectedEULA))
    let acceptItem = UIBarButtonItem.init(title: acceptTitle, style: .done, target: self, action: #selector(acceptedEULA))
    let middleSpacer = UIBarButtonItem.init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    self.toolbarItems = [rejectItem, middleSpacer, acceptItem]
    
    self.activityIndicatorView.center = self.view.center
    self.activityIndicatorView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    self.activityIndicatorView.startAnimating()
    self.view.addSubview(self.activityIndicatorView)
  }
  
  @objc func acceptedEULA() {
    OESettings.oeShared.userHasAcceptedEULA = true
    self.handler()
  }
  
  @objc func rejectedEULA() {
    OESettings.oeShared.userHasAcceptedEULA = false
    let alert = NYPLAlertUtils.alert(title: "NOTICE", message: "EULAHaveToAgree")
    let exitAction = UIAlertAction.init(title: OEUtils.LocalizedString("Cancel"), style: .destructive, handler: nil)
    alert.addAction(exitAction)
    self.present(alert, animated: false, completion: nil)
  }
  
  func loadWebView() {
    let url = URL.init(string: OEEULAViewController.onlineEULAPath)!
    let request = URLRequest.init(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 5.0)
    self.webView.loadRequest(request)
  }
  
  func loadWebViewFromBundle() {
    self.webView.loadRequest(
      URLRequest.init(
        url: URL.init(
          fileURLWithPath: Bundle.main.path(forResource: OEEULAViewController.offlineEULAPathComponent, ofType: nil)!
        )
      )
    )
  }
  
  //MARK: NSURLConnectionDelegate
  
  func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
    self.loadWebViewFromBundle()
  }
  
  func webViewDidFinishLoad(_ webView: UIWebView) {
    self.activityIndicatorView.stopAnimating()
  }
  
  func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
    if request.url?.absoluteString == OEEULAViewController.onlineEULAPath {
      return true
    } else if request.url?.lastPathComponent == OEEULAViewController.offlineEULAPathComponent {
      return true
    }
    return false
  }
}
