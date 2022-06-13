//
//  OELoginFirstBookVC.swift
//  Open eBooks
//
//  Created by Ettore Pasquini on 6/8/22.
//  Copyright © 2022 NYPL. All rights reserved.
//

import UIKit

class OELoginFirstBookVC: UIViewController {

  @IBOutlet var scrollView: UIScrollView!

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

  deinit {
    NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
    NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidHideNotification, object: nil)
  }

  // MARK: - UIViewController

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

    registerForKeyboardNotifications()
  }

  @IBAction func signIn() {
    Log.info(#function, "strunz")
  }

  // MARK: - Keyboard bs

  func registerForKeyboardNotifications() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(keyboardDidAppear(_:)),
                                           name: UIResponder.keyboardDidShowNotification,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(keyboardDidDisappear(_:)),
                                           name: UIResponder.keyboardDidHideNotification,
                                           object: nil)
  }

  @objc func keyboardDidAppear(_ notification: NSNotification) {
    guard
      let info = notification.userInfo,
      let rect = info[UIResponder.keyboardFrameBeginUserInfoKey] as? CGRect
    else {
      return
    }

    let kbSize = rect.size
    let insets = UIEdgeInsets(top: 0, left: 0, bottom: kbSize.height, right: 0)
    scrollView.contentInset = insets
    scrollView.scrollIndicatorInsets = insets

    // If active text field is hidden by keyboard, scroll it so it's visible
    var viewableFrame = self.view.frame;
    viewableFrame.size.height -= kbSize.height;
    let activeField = [accessCodeField, pinField].first { $0.isFirstResponder }
    if let activeField = activeField {
      if !viewableFrame.contains(activeField.frame.origin) {
        let scrollPoint = CGPoint(x: 0, y: activeField.frame.origin.y-kbSize.height)
        scrollView.setContentOffset(scrollPoint, animated: true)
      }
    }
  }

  @objc func keyboardDidDisappear(_ notification: NSNotification) {
    scrollView.contentInset = UIEdgeInsets.zero
    scrollView.scrollIndicatorInsets = UIEdgeInsets.zero
  }
}
