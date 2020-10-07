//
//  OETutorialChoiceViewController.swift
//  Open eBooks
//
//  Created by Kyle Sakai.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

class OETutorialChoiceViewController : UIViewController {
  var completionHandler: (()->Void)?
  
  var descriptionLabel: UILabel
  var firstBookLoginButton: UIButton
  var loginWithCleverButton: UIButton
  var requestCodesButton: UIButton
  var stackView: UIStackView
  
  init() {
    completionHandler = nil
    descriptionLabel = UILabel(frame: CGRect.zero)
    firstBookLoginButton = UIButton(type: .custom)
    loginWithCleverButton = UIButton(type: .custom)
    requestCodesButton = UIButton(type: .system)
    stackView = UIStackView(arrangedSubviews: [
      descriptionLabel,
      firstBookLoginButton,
      loginWithCleverButton
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
    
    title = NSLocalizedString("Log In", comment: "")
    
    descriptionLabel.font = UIFont(name: NYPLConfiguration.systemFontFamilyName(),
                                   size: 20.0)
    descriptionLabel.text = NSLocalizedString("You need to login to access the collection.", comment: "")
    descriptionLabel.textAlignment = .center
    descriptionLabel.numberOfLines = 0
    descriptionLabel.sizeToFit()
    
    firstBookLoginButton.setImage(UIImage(named: "FirstbookLoginButton"), for: .normal)
    firstBookLoginButton.addTarget(self, action: #selector(didSelectFirstBook), for: .touchUpInside)
    firstBookLoginButton.sizeToFit()
    
    loginWithCleverButton.setImage(UIImage(named: "CleverLoginButton"), for: .normal)
    loginWithCleverButton.addTarget(self, action: #selector(didSelectClever), for: .touchUpInside)
    loginWithCleverButton.sizeToFit()
    
    requestCodesButton.titleLabel?.font = UIFont.systemFont(ofSize: 20.0)
    requestCodesButton.setTitle(NSLocalizedString("Request New Codes", comment: ""),
                                for: .normal)
    requestCodesButton.addTarget(self, action: #selector(didSelectRequestCodes),
                                 for: .touchUpInside)
    requestCodesButton.sizeToFit()
    
    stackView.axis = .vertical
    stackView.distribution = .equalSpacing
    view.addSubview(stackView)
  }
  
  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    let minSize = min(view.frame.width, 414)
    
    // TODO: Magic number usage
    stackView.frame = CGRect(x: 0, y: 0, width: minSize, height: 160.0)
    stackView.centerInSuperview()
    stackView.integralizeFrame()
  }
  
  // MARK: -
  
  private func loginCompletionHandler() {
    view.window?.rootViewController?.dismiss(animated: true, completion: nil)
    dismiss(animated: true, completion: nil)
    
    NYPLSettings.shared.userHasSeenWelcomeScreen = true
    guard let appDelegate = UIApplication.shared.delegate else {
      Log.error("", "Could not load app delegate")
      return
    }
    
    guard let appWindow = appDelegate.window else {
      Log.error("", "Could not load app window")
      return
    }
    appWindow?.rootViewController = NYPLRootTabBarController.shared()
    
    let oldCompletionHandler = completionHandler
    completionHandler = nil
    oldCompletionHandler?.self()
  }
  
  @objc func didSelectFirstBook() {
    let libAccount = AccountsManager.shared.currentAccount
    let userAccount = NYPLUserAccount.sharedAccount()
    if libAccount?.details == nil {
      libAccount?.loadAuthenticationDocument(using: userAccount) { success in
        if success {
          NYPLAccountSignInViewController.requestCredentials(usingExistingBarcode: false, completionHandler: self.loginCompletionHandler)
        } else {
          let alert = NYPLAlertUtils.alert(title: "Bad Account Info", message: "Could not resolve OpenEBooks account data")
          self.present(alert, animated: true, completion: nil)
        }
      }
    } else {
      NYPLAccountSignInViewController.requestCredentials(usingExistingBarcode: false, completionHandler: loginCompletionHandler)
    }
  }
  
  @objc func didSelectClever() {
    // TODO: SIMPLY-3050
//    NYPLUserAccount.shared()?.removeAll()
//    CleverLoginViewController.loginWithCompletionHandler(loginCompletionHandler)
  }
  
  @objc func didSelectRequestCodes() {
    UIApplication.shared.open(NYPLConfiguration.openEBooksRequestCodesURL)
  }
  
  @objc class func showLoginPicker(handler: (()->Void)?) {
    let choiceVC = OETutorialChoiceViewController()
    choiceVC.completionHandler = handler
    let cancelBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: choiceVC, action: #selector(didSelectCancel))
    choiceVC.navigationItem.leftBarButtonItem = cancelBarButtonItem
    let navVC = UINavigationController(rootViewController: choiceVC)
    navVC.modalPresentationStyle = .formSheet
    if #available(iOS 13.0, *) {
      navVC.view.backgroundColor = .systemBackground
    } else {
      navVC.view.backgroundColor = .white
    }
    NYPLPresentationUtils.safelyPresent(navVC)
  }
  
  @objc func didSelectCancel() {
    navigationController?.presentingViewController?.dismiss(animated: true, completion: nil)
  }
}
