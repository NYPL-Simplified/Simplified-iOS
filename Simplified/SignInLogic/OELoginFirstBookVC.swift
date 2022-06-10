//
//  OELoginFirstBookVC.swift
//  Open eBooks
//
//  Created by Ettore Pasquini on 6/8/22.
//  Copyright © 2022 NYPL. All rights reserved.
//

import UIKit

class OELoginFirstBookVC: UIViewController {

  @IBOutlet var signInHeader: UILabel!

  @IBOutlet var accessCodeLabel: UILabel!
  @IBOutlet var accessCodeField: UITextField!
  @IBOutlet var pinLabel: UILabel!
  @IBOutlet var pinField: UITextField!

  @IBOutlet var signInButton: UIButton!

  @IBOutlet var troublesButton: UIButton!
  @IBOutlet var faqButton: UIButton!

  init() {
    super.init(nibName: "OELoginFirstBookVC", bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: UIViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.titleView = OELoginNavHeader()

    signInHeader.text = NSLocalizedString("Sign In", comment: "")
    accessCodeLabel.text = NSLocalizedString("Access Code", comment: "")
    accessCodeField.placeholder = NSLocalizedString("Access Code", comment: "")
    pinLabel.text = NSLocalizedString("PIN", comment: "")
    pinField.placeholder = NSLocalizedString("PIN", comment: "")

    signInButton.setTitle(NSLocalizedString("Sign In", comment: ""),
                          for: .normal)
    troublesButton.setTitle(NSLocalizedString("Having trouble signing in?", comment: ""),
                            for: .normal)
    faqButton.setTitle(NSLocalizedString("Frequently Asked Questions", comment: ""),
                            for: .normal)

  }

  @IBAction func signIn() {
    Log.info(#function, "strunz")
  }
}
