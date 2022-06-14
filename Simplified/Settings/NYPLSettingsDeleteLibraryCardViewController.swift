//
//  NYPLSettingsDeleteLibraryCardViewController.swift
//  Simplified
//
//  Created by Ernest Fan on 2022-06-13.
//  Copyright © 2022 NYPL. All rights reserved.
//

import UIKit
import MessageUI

@objc class NYPLSettingsDeleteLibraryCardViewController: UITableViewController {
  private let tableViewFooterViewHeight: CGFloat = 15.0
  
  private var supportEmail: String
  private var barcode: String
  
  @objc init(email: String, barcode: String) {
    self.supportEmail = email
    self.barcode = barcode
    
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupNavBar()
    setupUI()
  }
  
  // MARK: - TableViewSourceDelegate
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 3
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell(frame: .zero)
    cell.backgroundColor = NYPLConfiguration.primaryBackgroundColor
    if indexPath.section == 0 {
      // Library Card Deletion Description
      cell.textLabel?.attributedText = libraryCardDeletionDescription()
      cell.textLabel?.numberOfLines = 0
    } else if indexPath.section == 1 {
      // Email Button
      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.alignment = .center
      
      let attributedString = NSMutableAttributedString(string: NSLocalizedString("E-Mail to cancel your library card",
                                                                                 comment: "Button title for compose email"),
                                                       attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue,
                                                                    .foregroundColor: NYPLConfiguration.actionColor,
                                                                    .paragraphStyle: paragraphStyle,
                                                                    .font: UIFont.systemFont(ofSize: 14)])
      emailButton.setAttributedTitle(attributedString, for: .normal)
      cell.contentView.addSubview(emailButton)
      emailButton.autoPinEdge(toSuperviewEdge: .top, withInset: 0)
      emailButton.autoPinEdge(toSuperviewEdge: .bottom, withInset: 0)
      emailButton.autoCenterInSuperview()
    } else {
      // Show support email address
      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.alignment = .center
      paragraphStyle.lineSpacing = 1.25
      paragraphStyle.lineHeightMultiple = 1.25
      let string = NSLocalizedString("If the above link does not work, please email us at",
                                     comment: "Message to show support email address") + "\n\(self.supportEmail)"
      let attributedString = NSMutableAttributedString(string: string,
                                                       attributes: [.paragraphStyle: paragraphStyle,
                                                                    .font: UIFont.systemFont(ofSize: 12)])
      cell.textLabel?.attributedText = attributedString
      cell.textLabel?.numberOfLines = 0
    }
    return cell
  }
  
  override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    return tableViewFooterViewHeight
  }
  
  override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return footerView
  }
  // MARK: - Action
  
  @objc private func presentEmailComposer() {
    guard MFMailComposeViewController.canSendMail() else {
      let url = URL(string: "mailto:\(supportEmail)")!
      UIApplication.shared.open(url)
      return
    }
    
    let body = "\n\n---\nBarcode: \(barcode)"
    let mailComposeViewController = MFMailComposeViewController.init()
    mailComposeViewController.mailComposeDelegate = self
    mailComposeViewController.setSubject(NYPLLocalizationNotNeeded("Delete Library Card"))
    mailComposeViewController.setToRecipients([supportEmail])
    mailComposeViewController.setMessageBody(body, isHTML: false)
    present(mailComposeViewController, animated: true, completion: nil)
  }
  
  @objc private func dismissVC() {
    self.navigationController?.dismiss(animated: true, completion: nil)
  }
  
  // MARK: - Setup
  
  private func setupNavBar() {
    self.title = NSLocalizedString("Delete Library Card",
                                   comment: "Title for navigation bar")
    
    let backButton = UIBarButtonItem(title: NSLocalizedString("Cancel",
                                                              comment: "Button title for dismissing view controller"),
                                     style: .plain,
                                     target: self,
                                     action: #selector(dismissVC))
    
    self.navigationItem.leftBarButtonItem = backButton
  }
  
  private func setupUI() {
    self.tableView.backgroundColor = NYPLConfiguration.primaryBackgroundColor
    self.tableView.separatorStyle = .none
    self.tableView.allowsSelection = false
  }
  
  // MARK: - Helper
  
  lazy var footerView: UIView = {
    let view = UIView()
    view.backgroundColor = NYPLConfiguration.primaryBackgroundColor
    return view
  }()
  
  lazy var emailButton: UIButton = {
    let button = UIButton()
    button.addTarget(self, action: #selector(presentEmailComposer), for: .touchUpInside)
    return button
  }()
  
  private func libraryCardDeletionDescription() -> NSMutableAttributedString {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = 1.25
    paragraphStyle.lineHeightMultiple = 1.25
    
    let description = NSLocalizedString("DeleteLibraryCardDescription",
                                        comment: "Description of the delete action")
    let attributedString = NSMutableAttributedString(string:description,
                                                     attributes: [.font: UIFont.systemFont(ofSize: 14),
                                                                  .foregroundColor: NYPLConfiguration.primaryTextColor,
                                                                  .paragraphStyle: paragraphStyle]
    )

    return attributedString
  }
}

extension NYPLSettingsDeleteLibraryCardViewController: MFMailComposeViewControllerDelegate {
  func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
    controller.dismiss(animated: true, completion: nil)
    
    switch result {
    case .failed:
      if let error = error {
        let alert = NYPLAlertUtils.alert(title: "Error", error: error as NSError)
        NYPLAlertUtils.presentFromViewControllerOrNil(alertController: alert,
                                                      viewController: self,
                                                      animated: true,
                                                      completion: nil)
      }
    case .sent:
      // TODO: Check wordings with Risa
      let alert = UIAlertController(
        title: NSLocalizedString("Thank You", comment: "Alert title"),
        message: NSLocalizedString("Your email has been sent.", comment: "Alert message"),
        preferredStyle: .alert)
      alert.addAction(
        UIAlertAction(
          title: NSLocalizedString("OK", comment: ""),
          style: .default,
          handler: { _ in
            self.dismissVC()
          }))
      NYPLAlertUtils.presentFromViewControllerOrNil(alertController: alert,
                                                    viewController: self,
                                                    animated: true,
                                                    completion: nil)
    case .cancelled:
      fallthrough
    case .saved:
      fallthrough
    @unknown default:
      break
    }
  }
}
