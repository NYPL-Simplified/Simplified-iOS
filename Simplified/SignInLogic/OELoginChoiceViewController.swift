//
//  OELoginChoiceViewController.swift
//  Open eBooks
//
//  Created by Kyle Sakai.
//  Copyright © 2020 NYPL. All rights reserved.
//

import UIKit

class OELoginChoiceViewController : UIViewController {
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

  // MARK: - UIViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.titleView = OELoginNavHeader()
    if #available(iOS 14, *) {
      navigationItem.backButtonDisplayMode = .minimal
    } else {
      navigationItem.backBarButtonItem = UIBarButtonItem(title: "",
                                                         style: .plain,
                                                         target: nil,
                                                         action: nil)
    }

    headerLabel?.text = NSLocalizedString("Get Started", comment: "Login page header")
    subHeaderLabel?.text = NSLocalizedString("Login to access the collection", comment: "Login page sub header")
    cleverLoginButton?.setTitle(NSLocalizedString("Sign in with Clever", comment: "Login button text"), for: .normal)
    firstBookLoginButton?.setTitle(NSLocalizedString("Sign in with First Book", comment: "Login button text"), for: .normal)
    termsButton?.setTitle(NSLocalizedString("Terms of Use", comment: "Button Text"), for: .normal)
    privacyButton?.setTitle(NSLocalizedString("Privacy Notice", comment: "Button Text"), for: .normal)

    cleverLoginButton?.layer.borderColor = NYPLConfiguration.secondaryBackgroundColor.cgColor
    cleverLoginButton?.layer.cornerRadius = NYPLConfiguration.cornerRadius
    cleverLoginButton?.layer.borderWidth = 1
    firstBookLoginButton?.layer.borderColor = NYPLConfiguration.secondaryBackgroundColor.cgColor
    firstBookLoginButton?.layer.cornerRadius = NYPLConfiguration.cornerRadius
    firstBookLoginButton?.layer.borderWidth = 1
  }
  

  // MARK: - Actions
  
  @IBAction func didSelectClever() {
    didSelectAuthenticationMethod(.clever)
  }

  @IBAction func didSelectFirstBook() {
    guard let libraryAccount = AccountsManager.shared.currentAccount else {
      displayGenericAlert(for: "Unable to get library Account instance after selecting First Book as login choice")
      return
    }

    let firstBookVC = OELoginFirstBookVC(libraryAccount: libraryAccount,
                                         loginSuccessCompletion: completeLogin)
    navigationController?.pushViewController(firstBookVC, animated: true)
  }
  // MARK: - Private

  private func completeLogin() {
    view.window?.rootViewController?.dismiss(animated: true, completion: nil)
    dismiss(animated: true, completion: nil)

    guard let appDelegate = UIApplication.shared.delegate else {
      displayGenericAlert(for: "Could not load app delegate")
      return
    }

    guard let appWindow = appDelegate.window else {
      displayGenericAlert(for: "Could not load app window")
      return
    }

    Log.info(#function, "Installing main root VC")
    appWindow?.rootViewController = NYPLRootTabBarController.shared()
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

  // TODO: IOS-511: see NYPLSignInVC::presentAsModal

  private func presentSignInVC(for loginChoice: LoginChoice) {
    let signInVC = NYPLAccountSignInViewController(loginChoice: loginChoice)
    signInVC.presentIfNeeded(usingExistingCredentials: false,
                             completionHandler: self.completeLogin)
  }

  private func displayGenericAlert(for error: String) {
    Log.error(#file, error)
    let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""),
                                  message: NSLocalizedString("An unrecoverable error occurred. Please force-quit the app and try again.", comment: "Generic error message for internal errors"),
                                  preferredStyle: .alert)
    NYPLPresentationUtils.safelyPresent(alert)
  }
}
