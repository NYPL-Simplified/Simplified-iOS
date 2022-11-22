//
//  NYPLSettingsDeleteServerDataViewController.swift
//  Simplified
//
//  Created by Ernest Fan on 2022-06-03.
//  Copyright © 2022 NYPL. All rights reserved.
//

import UIKit

@objc protocol NYPLServerDataDeleting {
  func didDeleteServerData()
}

@objc class NYPLSettingsDeleteServerDataViewController: UITableViewController {
  private let tableViewFooterViewHeight: CGFloat = 15.0
  
  @objc weak var delegate: NYPLServerDataDeleting?
  private let syncSettingUpdater: NYPLServerSyncUpdating
  
  @objc init(delegate: NYPLServerDataDeleting) {
    self.syncSettingUpdater = NYPLRootTabBarController.shared().annotationsSynchronizer
    self.delegate = delegate
    
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
    return 2
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell(frame: .zero)
    cell.backgroundColor = NYPLConfiguration.primaryBackgroundColor
    if indexPath.section == 0 {
      // Data Deletion Description
      cell.textLabel?.attributedText = dataDeletionDescription()
      cell.textLabel?.numberOfLines = 0
    } else {
      // Delete Button
      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.alignment = .center
      let font = UIFont.customFont(forTextStyle: .body)
      let attributedString = NSMutableAttributedString(string: NSLocalizedString("Delete Reading Data",
                                                                                 comment: "Button title for delete reading data"),
                                                       attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue,
                                                                    .foregroundColor: NYPLConfiguration.actionColor,
                                                                    .paragraphStyle: paragraphStyle,
                                                                    .font: font as Any])
      deleteDataButton.setAttributedTitle(attributedString, for: .normal)
      cell.contentView.addSubview(deleteDataButton)
      deleteDataButton.autoPinEdge(toSuperviewEdge: .top, withInset: 0)
      deleteDataButton.autoPinEdge(toSuperviewEdge: .bottom, withInset: 0)
      deleteDataButton.autoCenterInSuperview()
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
  
  @objc private func deleteData() {
    let message = NSLocalizedString("Please wait...",
                                    comment: "Loading view message")
    let vc = NYPLActivityIndicatorMessageViewController(message: message)
    present(vc, animated: false)
    syncSettingUpdater
      .updateServerSyncSetting(toEnabled: false) { [weak self] success in
        NYPLMainThreadRun.asyncIfNeeded {
          guard let self = self else {
            return
          }
          self.dismiss(animated: false)
          if success {
            self.delegate?.didDeleteServerData()
          } else {
            self.showAlert()
          }
        }
      }
    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
      self.dismiss(animated: false)
      self.showAlert()
    }
  }
  
  @objc private func dismissVC() {
    self.navigationController?.dismiss(animated: true, completion: nil)
  }
  
  private func showAlert() {
    let title = NSLocalizedString("Delete Data Failed",
                                  comment: "Title for deletion failure alert")
    let message = NSLocalizedString("CheckConnection",
                                    comment: "Message for deletion failure alert")
    let alert = NYPLAlertUtils.alert(title: title, message: message)
    NYPLAlertUtils.presentFromViewControllerOrNil(alertController: alert,
                                                  viewController: self,
                                                  animated: true,
                                                  completion: nil)
  }
  
  // MARK: - Setup
  
  private func setupNavBar() {
    #if SIMPLYE
    self.title = NSLocalizedString("Delete my SimplyE Data",
                                   comment: "Title for navigation bar")
    #else
    self.title = NSLocalizedString("Delete my Open eBooks Data",
                                   comment: "Title for navigation bar")
    #endif
    
    let backButton = UIBarButtonItem(title: NSLocalizedString("Cancel",
                                                              comment: "Button title for dismissing view controller"),
                                     style: .plain,
                                     target: self,
                                     action: #selector(dismissVC))
    
    self.navigationItem.leftBarButtonItem = backButton
  }
  
  private func setupUI() {
    self.view.backgroundColor = NYPLConfiguration.primaryBackgroundColor
    self.tableView.separatorStyle = .none
    self.tableView.allowsSelection = false
  }
  
  // MARK: - Helper
  
  lazy var footerView: UIView = {
    let view = UIView()
    view.backgroundColor = NYPLConfiguration.primaryBackgroundColor
    return view
  }()
  
  lazy var deleteDataButton: UIButton = {
    let button = UIButton()
    button.addTarget(self, action: #selector(deleteData), for: .touchUpInside)
    return button
  }()
  
  private func dataDeletionDescription() -> NSMutableAttributedString {
    #if SIMPLYE
    let description = NSLocalizedString("DeleteServerDataDescriptionSimplyE",
                                        comment: "Description of the delete action")
    #else
    let description = NSLocalizedString("DeleteServerDataDescriptionOpeneBooks",
                                        comment: "Description of the delete action")
    #endif
    let font = UIFont.customFont(forTextStyle: .body)
    let attributedString = NSMutableAttributedString(string:description,
                                                     attributes: [.font: font as Any,
                                                                  .foregroundColor: NYPLConfiguration.primaryTextColor]
    )

    return attributedString
  }
}
