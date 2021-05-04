//
//  NYPLLibraryFinderSectionHeaderView.swift
//  Simplified
//
//  Created by Ernest Fan on 2021-04-26.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import UIKit

protocol NYPLLibraryFinderDisplaying: class {
  func toggleLibrarySection(shouldShow: Bool)
  var isMyLibraryHidden: Bool { get }
}

class NYPLLibraryFinderSectionHeaderView: UICollectionReusableView {
  private weak var displayer: NYPLLibraryFinderDisplaying?
  private var titleLabelLeadingConstraint: NSLayoutConstraint?
  private var type: NYPLLibraryFinderLibraryCellType = .myLibrary
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setupUI()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    // Redraw the border when dark mode activate/deactivate
    updateCustomBorder()
  }
  
  // MARK: - Configuration
  
  @discardableResult func configured(for type: NYPLLibraryFinderLibraryCellType, displayer: NYPLLibraryFinderDisplaying) -> UICollectionReusableView {
    switch type {
    case .myLibrary:
      titleLabelLeadingConstraint?.constant = 15.0
      expandButton.isHidden = false
      expandButton.isEnabled = true
      backgroundColor = NYPLLibraryFinderConfiguration.cellBackgroundColor
      titleLabel.text = NSLocalizedString("My Libraries", comment: "Title for my libraries section header")
    case .newLibrary:
      titleLabelLeadingConstraint?.constant = 5.0
      expandButton.isHidden = true
      expandButton.isEnabled = false
      backgroundColor = .clear
      titleLabel.text = NSLocalizedString("Add New Library", comment: "Title for my libraries section header")
    }
    self.displayer = displayer
    self.type = type
    rotateExpandButton()
    updateCustomBorder()
    return self
  }
  
  @objc private func didTapExpandButton() {
    guard let displayer = displayer else {
      return
    }
    displayer.toggleLibrarySection(shouldShow: displayer.isMyLibraryHidden)
  }
  
  // MARK: - UI
  
  private func rotateExpandButton() {
    guard let displayer = displayer else {
      return
    }
    if displayer.isMyLibraryHidden {
      self.expandButton.transform = CGAffineTransform.identity
    } else {
      self.expandButton.transform = CGAffineTransform(rotationAngle: .pi)
    }
  }
  
  private func updateCustomBorder() {
    layer.removeCustomBorders()
    guard type == .myLibrary else {
      return
    }
    layer.cornerRadius = 6.0
    layer.addBorder(side: .notBottom,
                    thickness: NYPLLibraryFinderConfiguration.borderWidth,
                    color: NYPLLibraryFinderConfiguration.borderColor.cgColor,
                    maskedCorners: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
  }
  
  private func setupUI() {
    addSubview(titleLabel)
    addSubview(expandButton)
    
    expandButton.autoPinEdgesToSuperviewEdges(with: .init(top: 5, left: 0, bottom: 0, right: 5), excludingEdge: .leading)
    expandButton.widthAnchor.constraint(equalTo: expandButton.heightAnchor).isActive = true
    
    titleLabel.autoPinEdge(toSuperviewEdge: .top, withInset: 5.0)
    titleLabel.autoPinEdge(toSuperviewEdge: .bottom)
    titleLabelLeadingConstraint = titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor)
    titleLabelLeadingConstraint?.isActive = true
    titleLabel.autoPinEdge(.trailing, to: .leading, of: expandButton)
  }
  
  // MARK: - Components
  
  private lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
    label.textColor = UIColor.defaultLabelColor()
    label.textAlignment = .left
    return label
  }()
  
  private lazy var expandButton: UIButton = {
    let button = UIButton(type: .system)
    button.setImage(UIImage(named: "ArrowDown"), for: .normal)
    button.transform = CGAffineTransform(rotationAngle: .pi)
    button.addTarget(self, action: #selector(didTapExpandButton), for: .touchUpInside)
    return button
  }()
}
