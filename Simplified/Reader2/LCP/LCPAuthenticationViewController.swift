//
//  LCPAuthenticationViewController.swift
//  r2-testapp-swift
//
//  Created by Mickaël Menu on 01.03.19.
//
//  Copyright 2019 Readium Foundation. All rights reserved.
//  Use of this source code is governed by a BSD-style license which is detailed
//  in the LICENSE file present in the project repository where this source code is maintained.
//

#if LCP

import SafariServices
import UIKit
import ReadiumLCP


protocol LCPAuthenticationDelegate: AnyObject {
  
  /// Authenticate with passphrase.
  /// The function calls the callback set for document ID in the license
  /// - Parameters:
  ///   - license: Information to show to the user about the license being opened.
  ///   - passphrase: License passphrase
  func authenticate(_ license: LCPAuthenticatedLicense, with passphrase: String)

  /// Cancel authentication. The function removes authentication callback associated with the license document ID
  /// - Parameter license:Information to show to the user about the license being opened.
  func didCancelAuthentication(of license: LCPAuthenticatedLicense)
  
}

class LCPAuthenticationViewController: UIViewController {
  
  // Authentication delegate - LCPLibraryService
  weak var delegate: LCPAuthenticationDelegate?
  
  @IBOutlet weak var scrollView: UIScrollView!
  // Passphrase hint from the license
  @IBOutlet weak var hintLabel: UILabel!
  // LCP protection info
  @IBOutlet weak var promptLabel: UILabel!
  // LCP provider info
  @IBOutlet weak var messageLabel: UILabel!
  // Passphrase field for the license
  @IBOutlet weak var passphraseField: UITextField!
  // If the license contains one or several supoprt links, show support information
  @IBOutlet weak var supportButton: UIButton!
  
  private let licenseInfo: LCPLicenseInfo
  private let reason: LCPAuthenticationReason
  
  // Support links - can be web URLs, emails or phone numbers
  private let supportLinks: [(Link, URL)]
  
  init(licenseInfo: LCPLicenseInfo, reason: LCPAuthenticationReason) {
    self.licenseInfo = licenseInfo
    self.reason = reason
    self.supportLinks = licenseInfo.supportLinks
      .compactMap { link -> (Link, URL)? in
        guard let url = URL(string: link.href), UIApplication.shared.canOpenURL(url) else {
          return nil
        }
        return (link, url)
    }
    
    super.init(nibName: nil, bundle: nil)
    
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    var provider = licenseInfo.provider
    if let providerHost = URL(string: provider)?.host {
      provider = providerHost
    }
    
    supportButton.isHidden = supportLinks.isEmpty
    
    let label = UILabel()
    
    switch reason {
    case .passphraseNotFound:
      label.text = NSLocalizedString("Passphrase Required", comment: "Reason to ask for the passphrase when it was not found ")
    case .invalidPassphrase:
      label.text = NSLocalizedString("Incorrect Passphrase", comment: "Reason to ask for the passphrase when the one entered was incorrect")
      passphraseField.layer.borderWidth = 1
      passphraseField.layer.borderColor = UIColor.red.cgColor
    }
    
    label.sizeToFit()
    let leftItem = UIBarButtonItem(customView: label)
    self.navigationItem.leftBarButtonItem = leftItem
    
    promptLabel.text = NSLocalizedString("This publication is protected by Readium LCP.", comment: "Prompt message when asking for the passphrase")
    messageLabel.text = String(format: NSLocalizedString("In order to open it, we need to know the passphrase required by:\n\n%@\n\nTo help you remember it, the following hint is available:", comment: "More instructions about the passphrase"), provider)
    hintLabel.text = licenseInfo.hint
    
    let cancelItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.cancel, target: self, action: #selector(LCPAuthenticationViewController.cancel(_:)));
    navigationItem.rightBarButtonItem = cancelItem;
    
  }
  
  @IBAction func authenticate(_ sender: Any) {
    let passphrase = passphraseField.text ?? ""
    delegate?.authenticate(licenseInfo.license, with: passphrase)
    dismiss(animated: true)
  }
  
  @IBAction func cancel(_ sender: Any) {
    delegate?.didCancelAuthentication(of: licenseInfo.license)
    dismiss(animated: true)
  }
  
  @IBAction func showSupportLink(_ sender: Any) {
    guard !supportLinks.isEmpty else {
      return
    }
    
    func open(_ url: URL) {
        UIApplication.shared.open(url)
    }
    
    if let (_, url) = supportLinks.first, supportLinks.count == 1 {
      open(url)
      return
    }
    
    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    for (link, url) in supportLinks {
      let title: String = {
        if let title = link.title {
          return title
        }
        if let scheme = url.scheme {
          switch scheme {
          case "http", "https":
            return NSLocalizedString("Website", comment: "Contact the support through a website")
          case "tel":
            return NSLocalizedString("Phone", comment: "Contact the support by phone")
          case "mailto":
            return NSLocalizedString("Mail", comment: "Contact the support by mail")
          default:
            break
          }
        }
        return NSLocalizedString("Support", comment: "Button to contact the support when entering the passphrase")
      }()
      
      let action = UIAlertAction(title: title, style: .default) { _ in
        open(url)
      }
      alert.addAction(action)
    }
    alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel opening the LCP protected publication"), style: .cancel))
    
    if let popover = alert.popoverPresentationController, let sender = sender as? UIView {
      popover.sourceView = sender
      var rect = sender.bounds
      rect.origin.x = sender.center.x - 1
      rect.size.width = 2
      popover.sourceRect = rect
    }
    present(alert, animated: true)
  }
  
  @IBAction func showHintLink(_ sender: Any) {
    guard let href = licenseInfo.hintLink?.href, let url = URL(string: href) else {
      return
    }
    
    let browser = SFSafariViewController(url: url)
    browser.modalPresentationStyle = .currentContext
    present(browser, animated: true)
  }
  
  /// Makes sure the form contents in scrollable when the keyboard is visible.
  @objc func keyboardWillChangeFrame(_ note: Notification) {
    guard let window = UIApplication.shared.keyWindow, let scrollView = scrollView, let scrollViewSuperview = scrollView.superview, let info = note.userInfo else {
      return
    }
    
    var keyboardHeight: CGFloat = 0
    if note.name == UIResponder.keyboardWillChangeFrameNotification {
      guard let keyboardFrame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
        return
      }
      keyboardHeight = keyboardFrame.height
    }
    
    // Calculates the scroll view offsets in the coordinate space of of our window
    let scrollViewFrame = scrollViewSuperview.convert(scrollView.frame, to: window)
    
    var contentInset = scrollView.contentInset
    // Bottom inset is the part of keyboard that is covering the tableView
    contentInset.bottom = keyboardHeight - (window.frame.height - scrollViewFrame.height - scrollViewFrame.origin.y) + 16
    
    self.scrollView.contentInset = contentInset
    self.scrollView.scrollIndicatorInsets = contentInset
  }
  
}


extension LCPAuthenticationViewController: UITextFieldDelegate {
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    authenticate(textField)
    return false
  }
  
}

#endif
