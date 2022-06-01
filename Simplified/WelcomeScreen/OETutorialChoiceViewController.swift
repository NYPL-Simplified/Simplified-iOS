//
//  OETutorialChoiceViewController.swift
//  Open eBooks
//
//  Created by Kyle Sakai.
//  Copyright © 2020 NYPL. All rights reserved.
//

import UIKit

class OETutorialChoiceViewController : UIViewController {
  var descriptionLabel: UILabel
  var firstBookLoginButton: UIButton
  var loginWithCleverButton: UIButton
  var requestCodesButton: UIButton
  var stackView: UIStackView
  
  init() {
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
    
    title = NSLocalizedString("LogIn", comment: "")
    
    descriptionLabel.font = NYPLConfiguration.welcomeScreenFont()
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
    let minSize = min(view.frame.width, 428)
    
    // TODO: Magic number usage
    stackView.frame = CGRect(x: 0, y: 0, width: minSize, height: 170.0)
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
    Log.info(#function, "Installing main root VC")
    appWindow?.rootViewController = NYPLRootTabBarController.shared()
  }

  @objc func didSelectFirstBook() {
    didSelectAuthenticationMethod(.firstBook)
  }

  @objc func didSelectClever() {
    didSelectAuthenticationMethod(.clever)
  }

  private func didSelectAuthenticationMethod(_ loginChoice: LoginChoice) {
    let libAccount = AccountsManager.shared.currentAccount
    let userAccount = NYPLUserAccount.sharedAccount()
    if libAccount?.details == nil {
      libAccount?.loadAuthenticationDocument(using: userAccount) { success, error in
        NYPLMainThreadRun.asyncIfNeeded {
          if success {
            self.presentSignInVC(for: loginChoice)
          } else {
            let alert = NYPLAlertUtils.alert(title: "Sign-in Error", message: "We could not find a match for the credentials provided.")
            self.present(alert, animated: true, completion: nil)
          }
        }
      }
    } else {
      presentSignInVC(for: loginChoice)
    }
  }

  private func presentSignInVC(for loginChoice: LoginChoice) {
    let signInVC = NYPLAccountSignInViewController(loginChoice: loginChoice)
    signInVC.presentIfNeeded(usingExistingCredentials: false,
                             completionHandler: self.loginCompletionHandler)
  }

  @objc func didSelectRequestCodes() {
    UIApplication.shared.open(NYPLConfiguration.openEBooksRequestCodesURL)
  }
  
  class func showLoginPicker() {
    let choiceVC = OETutorialChoiceViewController()
    let cancelBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: choiceVC, action: #selector(didSelectCancel))
    choiceVC.navigationItem.leftBarButtonItem = cancelBarButtonItem
    let navVC = UINavigationController(rootViewController: choiceVC)
    navVC.modalPresentationStyle = .formSheet
    navVC.view.backgroundColor = NYPLConfiguration.welcomeTutorialBackgroundColor
    NYPLPresentationUtils.safelyPresent(navVC)
  }
  
  @objc func didSelectCancel() {
    navigationController?.presentingViewController?.dismiss(animated: true, completion: nil)
  }
}
