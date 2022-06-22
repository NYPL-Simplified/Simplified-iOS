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

  weak var postLoginConfigurator: OEAppUIStructureConfigurating?
  
  init(postLoginConfigurator: OEAppUIStructureConfigurating) {
    self.postLoginConfigurator = postLoginConfigurator
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
      NYPLAlertUtils.presentUnrecoverableAlert(for: "Unable to get library Account instance after selecting First Book as login choice")
      return
    }

    let firstBookVC = OELoginFirstBookVC(libraryAccount: libraryAccount,
                                         postLoginConfigurator: postLoginConfigurator)
    navigationController?.pushViewController(firstBookVC, animated: true)
  }

  @IBAction func showEULA() {
    let eulaVC = NYPLWelcomeEULAViewController(displayOnly: true)
    navigationController?.pushViewController(eulaVC, animated: true)
  }

  @IBAction func showPrivacyNotice() {
    let urlProvider = NYPLLibraryAccountURLsProvider(account: AccountsManager.shared.currentAccount)
    let privacyURL = urlProvider.accountURL(forType: .privacyPolicy)
    let vc = RemoteHTMLViewController(
      URL: privacyURL,
      title: NSLocalizedString("PrivacyPolicy", comment: "Title for Privacy Policy section"),
      failureMessage: NSLocalizedString("The page could not load due to a connection error.", comment: "")
    )

    navigationController?.pushViewController(vc, animated: true)
  }

  // MARK: - Private

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
}
