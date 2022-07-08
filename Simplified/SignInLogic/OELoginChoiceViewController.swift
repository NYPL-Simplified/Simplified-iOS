//
//  OELoginChoiceViewController.swift
//  Open eBooks
//
//  Created by Kyle Sakai.
//  Copyright © 2020 NYPL. All rights reserved.
//

import UIKit
import QuartzCore

class OELoginChoiceViewController : UIViewController {
  @IBOutlet var headerLabel: UILabel?
  @IBOutlet var subHeaderLabel: UILabel?
  @IBOutlet var cleverLoginButton: UIButton?
  @IBOutlet var firstBookLoginButton: UIButton?
  @IBOutlet var termsButton: UIButton?
  @IBOutlet var privacyButton: UIButton?

  weak var postLoginConfigurator: OEAppUIStructureConfigurating?
  var cleverHelper: OELoginCleverHelper?
  
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
    subHeaderLabel?.text = NSLocalizedString("Login to access the collection.", comment: "Login page sub header")
    cleverLoginButton?.setTitle(NSLocalizedString("Sign in with Clever", comment: "Login button text"), for: .normal)
    firstBookLoginButton?.setTitle(NSLocalizedString("Sign in with First Book", comment: "Login button text"), for: .normal)
    termsButton?.setTitle(NSLocalizedString("Terms of Use", comment: "Button Text"), for: .normal)
    privacyButton?.setTitle(NSLocalizedString("Privacy Notice", comment: "Button Text"), for: .normal)

    [cleverLoginButton, firstBookLoginButton].forEach {
      // rounded corners
      $0?.layer.cornerRadius = NYPLConfiguration.cornerRadius
      // drop shadows
      $0?.layer.masksToBounds = false
      $0?.layer.shadowOpacity = NYPLConfiguration.shadowOpacity
      $0?.layer.shadowRadius = NYPLConfiguration.shadowRadius
      $0?.layer.shadowOffset = NYPLConfiguration.shadowOffset
    }

    updateColors()
  }

  // this override is to fix colors in case the user transitions from Light
  // mode to Dark mode or viceversa.
  override func traitCollectionDidChange(_ previousTraits: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraits)

    if #available(iOS 12.0, *) {
      if let previousStyle = previousTraits?.userInterfaceStyle {
        if previousStyle != UIScreen.main.traitCollection.userInterfaceStyle {
          updateColors()
        }
      }
    }
  }

  // MARK: - Actions

  @IBAction func didTouchDownOnButton(_ sender: Any) {
    guard let button = sender as? UIButton else {
      return
    }

    if #available(iOS 13.0, *), UIScreen.main.traitCollection.userInterfaceStyle == .dark {
      if button == cleverLoginButton {
        button.backgroundColor = NYPLConfiguration.cleverColor
      } else if button == firstBookLoginButton {
        button.backgroundColor = NYPLConfiguration.firstBookColor
      }
      return
    }

    button.backgroundColor = NYPLConfiguration.secondaryBackgroundColor
  }

  @IBAction func didTouchUpOutsideButton(_ sender: Any) {
    resetButtonDefaultColors()
  }

  @IBAction func didSelectClever() {
    resetButtonDefaultColors()

    // very defensive: in OE there's only one library account, so at this point
    // the cleverHelper (which requires a lib account) should already be created.
    if cleverHelper == nil {
      cleverHelper = makeCleverHelper()
    }

    cleverHelper?.startCleverFlow(onNavigationController: navigationController)
  }

  @IBAction func didSelectFirstBook() {
    resetButtonDefaultColors()

    guard let libraryAccount = AccountsManager.shared.currentAccount else {
      NYPLAlertUtils.presentUnrecoverableAlert(for: "Unable to get library Account instance after selecting First Book as login choice")
      return
    }

    let firstBookVC = OELoginFirstBookVC(libraryAccount: libraryAccount,
                                         postLoginConfigurator: postLoginConfigurator)
    navigationController?.pushViewController(firstBookVC, animated: true)
  }

  @IBAction func showEULA() {
    let eulaVC = OEEULAViewController(displayOnly: true)
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

  // MARK: - Private helpers

  private func makeCleverHelper() -> OELoginCleverHelper? {
    guard let libraryAccount = AccountsManager.shared.currentAccount else {
      NYPLAlertUtils.presentUnrecoverableAlert(for: "Unable to get library Account instance after selecting First Book as login choice")
      return nil
    }

    return OELoginCleverHelper(libraryAccount: libraryAccount,
                               postLoginConfigurator: postLoginConfigurator)
  }

  private func updateColors() {
    // set up colors per our scheme
    view.backgroundColor = NYPLConfiguration.primaryBackgroundColor
    navigationController?.navigationBar.tintColor = NYPLConfiguration.actionColor
    cleverLoginButton?.setTitleColor(NYPLConfiguration.cleverColor, for: .normal)
    firstBookLoginButton?.setTitleColor(NYPLConfiguration.firstBookColor, for: .normal)
    resetButtonDefaultColors()
    termsButton?.setTitleColor(NYPLConfiguration.actionColor, for: .normal)
    privacyButton?.setTitleColor(NYPLConfiguration.actionColor, for: .normal)
    cleverLoginButton?.layer.shadowColor = NYPLConfiguration.shadowColor.cgColor
    firstBookLoginButton?.layer.shadowColor = NYPLConfiguration.shadowColor.cgColor
  }

  private func resetButtonDefaultColors() {
    cleverLoginButton?.backgroundColor = NYPLConfiguration.buttonBackgroundColor
    firstBookLoginButton?.backgroundColor = NYPLConfiguration.buttonBackgroundColor
    if #available(iOS 13.0, *), UIScreen.main.traitCollection.userInterfaceStyle == .dark {
      [cleverLoginButton, firstBookLoginButton].forEach {
        $0?.setTitleColor(NYPLConfiguration.primaryTextColor, for: .highlighted)
        $0?.layer.borderWidth = 1
        $0?.layer.borderColor = NYPLConfiguration.fieldBorderColor.cgColor
      }
    } else {
      [cleverLoginButton, firstBookLoginButton].forEach {
        $0?.setTitleColor(NYPLConfiguration.cleverColor, for: .highlighted)
        $0?.layer.borderWidth = 0
      }
    }
  }
}
