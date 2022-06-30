//
//  OECleverReauthenticatorVC.swift
//  Open eBooks
//
//  Created by Ettore Pasquini on 6/24/22.
//  Copyright © 2022 NYPL. All rights reserved.
//

import UIKit

class OECleverReauthenticatorVC: UIViewController {
  @IBOutlet var explainerLabel: UILabel!
  @IBOutlet var refreshAuthButton: UIButton!

  private let cleverHelper: OELoginCleverHelper

  init(libraryAccount: Account,
       postLoginConfigurator: OEAppUIStructureConfigurating?) {
    cleverHelper = OELoginCleverHelper(libraryAccount: libraryAccount,
                                       postLoginConfigurator: postLoginConfigurator)
    super.init(nibName: "OECleverReauthenticatorVC", bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.titleView = OELoginNavHeader()

    explainerLabel?.text = NSLocalizedString("You have timed out. Please sign back in.", comment: "Explanation text for why we need to refresh Clever authentication")
    refreshAuthButton?.setTitle(NSLocalizedString("Sign in on Clever", comment: "Text for button to refresh Clever authentication"), for: .normal)

    updateColors()
  }

  // this override is to fix colors in case the user transitions from
  // Light mode to Dark mode or viceversa.
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

  var businessLogic: NYPLSignInBusinessLogic {
    return cleverHelper.signInBusinessLogic
  }
  
  @IBAction func didTapRefresh() {
    cleverHelper.startCleverFlow(onNavigationController: navigationController)
  }

  private func updateColors() {
    // set up colors per our scheme
    refreshAuthButton?.setTitleColor(NYPLConfiguration.actionColor, for: .normal)
    refreshAuthButton?.layer.borderColor = NYPLConfiguration.secondaryBackgroundColor.cgColor
  }
}
