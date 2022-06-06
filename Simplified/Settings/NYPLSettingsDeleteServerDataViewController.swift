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

@objc class NYPLSettingsDeleteServerDataViewController: UIViewController {
  @objc weak var delegate: NYPLServerDataDeleting?
  
  @objc init(delegate: NYPLServerDataDeleting) {
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
  
  // MARK: - Action
  
  @objc func deleteData() {
    let message = NSLocalizedString("Please wait...",
                                    comment: "Loading view message")
    let vc = NYPLActivityIndicatorMessageViewController(with: message)
    present(vc, animated: false)
    NYPLAnnotations.updateServerSyncSetting(toEnabled: false) { [weak self] success in
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
  
  @objc func dismissVC() {
    self.navigationController?.dismiss(animated: true, completion: nil)
  }
  
  func showAlert() {
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
  
  func setupNavBar() {
    self.title = NSLocalizedString("Delete my SimplyE Data",
                                   comment: "Title for navigation bar")
    
    let backButton = UIBarButtonItem(title: NSLocalizedString("Cancel",
                                                              comment: "Button title for dismissing view controller"),
                                     style: .plain,
                                     target: self,
                                     action: #selector(dismissVC))
    
    self.navigationItem.leftBarButtonItem = backButton
  }
  
  func setupUI() {
    self.view.backgroundColor = NYPLConfiguration.primaryBackgroundColor
    deleteDataButton.autoSetDimension(.height, toSize: 40)
    let subviews = [deleteDescriptionLabel, deleteDataButton, UIView()]
    let stackView = UIStackView(arrangedSubviews: subviews)
    stackView.alignment = .fill
    stackView.distribution = .fill
    stackView.axis = .vertical
    stackView.spacing = 20
    
    view.addSubview(stackView)
    stackView.autoPinEdgesToSuperviewSafeArea(with: .init(top: 20, left: 20, bottom: 20, right: 20))
  }
  
  // MARK: - UI Properties
  
  lazy var deleteDescriptionLabel: UILabel = {
    let label = UILabel(frame: .zero)
    label.attributedText = dataDeletionDescription()
    label.textAlignment = .left
    label.textColor = NYPLConfiguration.primaryTextColor
    label.font = UIFont.systemFont(ofSize: 14)
    label.numberOfLines = 0
    return label
  }()
  
  lazy var deleteDataButton: UIButton = {
    let button = UIButton(type: .system)
    let attributedString = NSMutableAttributedString(string: NSLocalizedString("Delete Reading Data",
                                                                               comment: "Button title for delete reading data"),
                                                     attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue,
                                                                  .foregroundColor: NYPLConfiguration.actionColor])
    button.setAttributedTitle(attributedString, for: .normal)
    button.titleLabel?.textAlignment = .center
    button.addTarget(self, action: #selector(deleteData), for: .touchUpInside)
    return button
  }()
  
  func dataDeletionDescription() -> NSMutableAttributedString {
    let attributedString = NSMutableAttributedString(string:
    """
    SimplyE does not create any accounts outside of your library card. The content that the SimplyE app saves is:

    * your library card information to log into your library
    * your last known place in the book you’re reading or listening to
    * and any bookmarks or highlights you’ve created for your current book

    Your account information is saved outside of your current device if you specifically permit us to save it. If you only want your bookmarks and reading location deleted, please go to Settings/Accounts/The New York Public Library. Set the “Sync Bookmarks” toggle to OFF, then come back to this page and tap “Delete Reading Data”. Then you can log out, and SimplyE will no longer save any of your information.
    """
    )

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = 1.25
    paragraphStyle.lineHeightMultiple = 1.25
    attributedString.addAttribute(NSAttributedString.Key.paragraphStyle,
                                  value:paragraphStyle,
                                  range:NSMakeRange(0, attributedString.length))

    return attributedString
  }
}
