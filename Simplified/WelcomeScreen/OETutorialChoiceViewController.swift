//
//  OETutorialChoiceViewController.swift
//  Open eBooks
//
//  Created by Kyle Sakai.
//  Copyright © 2020 NYPL. All rights reserved.
//

import UIKit

class OETutorialChoiceViewController : UIViewController {
  @IBOutlet var headerLabel: UILabel?
  @IBOutlet var subHeaderLabel: UILabel?
  @IBOutlet var cleverLoginButton: UIButton?
  @IBOutlet var firstBookLoginButton: UIButton?
  @IBOutlet var termsButton: UIButton?
  @IBOutlet var privacyButton: UIButton?

  
  init() {
    super.init(nibName: "OELoginChoice", bundle: nil)
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: UIViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    headerLabel?.text = NSLocalizedString("Get Started", comment: "Login page header")
    subHeaderLabel?.text = NSLocalizedString("Login to access the collection", comment: "Login page sub header")
    cleverLoginButton?.setTitle(NSLocalizedString("Sign in with Clever", comment: "Login button text"), for: .normal)
    firstBookLoginButton?.setTitle(NSLocalizedString("Sign in with First Book", comment: "Login button text"), for: .normal)
    termsButton?.setTitle(NSLocalizedString("Terms of Use", comment: "Button Text"), for: .normal)
    privacyButton?.setTitle(NSLocalizedString("Privacy Notice", comment: "Button Text"), for: .normal)
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

  @IBAction func didSelectClever() {
    didSelectAuthenticationMethod(.clever)
  }

  @IBAction func didSelectFirstBook() {
    didSelectAuthenticationMethod(.firstBook)
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
