class OETutorialChoiceViewController : UIViewController {
  var completionHandler: (()->Void)?
  
  var descriptionLabel: UILabel
  var enterCodeButton: UIButton
  var loginWithCleverButton: UIButton
  var requestCodesButton: UIButton
  var stackView: UIStackView
  
  init() {
    completionHandler = nil
    self.descriptionLabel = UILabel.init(frame: CGRect.zero)
    self.enterCodeButton = UIButton.init(type: .custom)
    self.loginWithCleverButton = UIButton.init(type: .custom)
    self.requestCodesButton = UIButton.init(type: .system)
    self.stackView = UIStackView.init(arrangedSubviews: [
      self.descriptionLabel,
      self.enterCodeButton,
      self.loginWithCleverButton
    ])
    super.init(nibName: nil, bundle: nil)
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: UIViewController
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = OEUtils.LocalizedString("Log In")
    
    self.descriptionLabel.font = UIFont.systemFont(ofSize: 20.0)
    self.descriptionLabel.text = OEUtils.LocalizedString("TutorialChoiceViewControllerDescription")
    self.descriptionLabel.textAlignment = .center
    self.descriptionLabel.numberOfLines = 0
    self.descriptionLabel.sizeToFit()
    
    self.enterCodeButton.setImage(UIImage.init(named: "FirstbookLoginButton"), for: .normal)
    self.enterCodeButton.addTarget(self, action: #selector(didSelectEnterCodes), for: .touchUpInside)
    self.enterCodeButton.sizeToFit()
    
    self.loginWithCleverButton.setImage(UIImage.init(named: "CleverLoginButton"), for: .normal)
    self.loginWithCleverButton.addTarget(self, action: #selector(didSelectClever), for: .touchUpInside)
    self.loginWithCleverButton.sizeToFit()
    
    self.requestCodesButton.titleLabel?.font = UIFont.systemFont(ofSize: 20.0)
    self.requestCodesButton.setTitle(OEUtils.LocalizedString("TutorialChoiceRequestCodes"), for: .normal)
    self.requestCodesButton.addTarget(self, action: #selector(didSelectRequestCodes), for: .touchUpInside)
    self.requestCodesButton.sizeToFit()
    
    self.stackView.axis = .vertical
    self.stackView.distribution = .equalSpacing
    self.view.addSubview(self.stackView)
  }
  
  override func viewWillLayoutSubviews() {
    let minSize = min(self.view.frame.width, 414)
    
    // Magic number usage
    self.stackView.frame = CGRect.init(x: 0, y: 0, width: minSize, height: 160.0)
    self.stackView.centerInSuperview()
    self.stackView.integralizeFrame()
  }
  
  // MARK: -
  
  fileprivate func loginCompletionHandler() {
    self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
    self.dismiss(animated: true, completion: nil)
    
    NYPLSettings.shared.userHasSeenWelcomeScreen = true
    guard let appDelegate = UIApplication.shared.delegate as? OEAppDelegate else {
      Log.error("", "Could not load app delegate")
      return
    }
    
    appDelegate.window?.rootViewController = NYPLRootTabBarController.shared()
    
    let oldCompletionHandler = self.completionHandler
    self.completionHandler = nil
    oldCompletionHandler?.self()
  }
  
  @objc func didSelectEnterCodes() {
    NYPLAccount.shared()?.removeBarcodeAndPIN()
    if AccountsManager.shared.currentAccount?.details == nil {
      AccountsManager.shared.currentAccount?.loadAuthenticationDocument(preferringCache: true, completion: { (success) in
        if success {
          NYPLAccountSignInViewController.requestCredentials(usingExistingBarcode: false, completionHandler: self.loginCompletionHandler)
        } else {
          let alert = NYPLAlertUtils.alert(title: "Bad Acount Info", message: "Could not resolve OpenEBooks account data")
          self.present(alert, animated: true, completion: nil)
        }
      })
    } else {
      NYPLAccountSignInViewController.requestCredentials(usingExistingBarcode: false, completionHandler: loginCompletionHandler)
    }
  }
  
  @objc func didSelectClever() {
    NYPLAccount.shared()?.removeAll()
    CleverLoginViewController.loginWithCompletionHandler(loginCompletionHandler)
  }
  
  @objc func didSelectRequestCodes() {
    UIApplication.shared.openURL(OEConfiguration.oeShared.openEBooksRequestCodesURL)
  }
  
  class func showLoginPicker(handler: (()->Void)?) {
    let choiceVC = OETutorialChoiceViewController()
    choiceVC.completionHandler = handler
    let cancelBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .cancel, target: choiceVC, action: #selector(didSelectCancel))
    choiceVC.navigationItem.leftBarButtonItem = cancelBarButtonItem
    let navVC = UINavigationController.init(rootViewController: choiceVC)
    navVC.modalPresentationStyle = .formSheet
    if #available(iOS 13.0, *) {
      navVC.view.backgroundColor = .systemBackground
    } else {
      navVC.view.backgroundColor = .white
    }
    OEUtils.safelyPresent(navVC, animated: true, completion: nil)
  }
  
  @objc func didSelectCancel() {
    self.navigationController?.presentingViewController?.dismiss(animated: true, completion: nil)
  }
}
