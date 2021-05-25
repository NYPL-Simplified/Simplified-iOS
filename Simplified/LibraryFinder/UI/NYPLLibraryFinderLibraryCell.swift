//
//  NYPLLibraryFinderLibraryCell.swift
//  Simplified
//
//  Created by Ernest Fan on 2021-04-22.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import UIKit

enum NYPLLibraryFinderLibraryCellType {
  case myLibrary
  case newLibrary
}

class NYPLLibraryFinderLibraryCell: UICollectionViewCell {
  private let stackViewSpacing: CGFloat = 4.0
  
  private var badgeLabelWidthConstraint: NSLayoutConstraint?
  private var badgeLabelHeightConstraint: NSLayoutConstraint?
  
  private var type: NYPLLibraryFinderLibraryCellType = .myLibrary
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setupUI()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    // Redraw the border when the height of the cell changes
    updateBorder()
  }
  
  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    // Redraw the border when dark mode activate/deactivate
    updateBorder()
  }
  
  override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
    // The vertical fitting priority is
    // .fittingSizeLevel meaning the cell will find the
    // height that best fits the content
    let size = super.systemLayoutSizeFitting(
      targetSize,
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel
    )
    
    return size
  }
  
  // MARK: - UI
  
  func configureCell(type: NYPLLibraryFinderLibraryCellType, account: Account) {
    self.type = type
    configureBorder(for: type)
    
    nameLabel.text = account.name
    // TODO: iOS-36 Assign data value to UI componenets after parser and data model are updated
    descriptionLabel.text = account.subtitle
    distanceLabel.text = account.distance
    postalCodeLabel.text = account.area
    
    configureBadgeLabel(text: account.areaType)
  }
  
  private func setupUI() {
    backgroundColor = NYPLLibraryFinderConfiguration.cellBackgroundColor
    layer.cornerRadius = NYPLLibraryFinderConfiguration.cellCornerRadius(type: self.type)
    
    divider.autoPinEdgesToSuperviewEdges(with: .init(top: 0, left: 15, bottom: 0, right: 15), excludingEdge: .bottom)
    divider.heightAnchor.constraint(equalToConstant: NYPLLibraryFinderConfiguration.borderWidth).isActive = true
    
    leftStackView.autoPinEdge(.top, to: .bottom, of: divider, withOffset: 20)
    leftStackView.autoPinEdge(toSuperviewEdge: .leading, withInset: 15)
    leftStackView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 20)
    
    badgeLabel.autoPinEdge(.leading, to: .trailing, of: leftStackView, withOffset: 20)
    badgeLabel.autoPinEdge(.top, to: .bottom, of: divider, withOffset: 20)
    badgeLabel.autoPinEdge(toSuperviewEdge: .trailing, withInset: 15)
    
    badgeLabelWidthConstraint = badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60)
    badgeLabelWidthConstraint?.isActive = true
    badgeLabelHeightConstraint = badgeLabel.heightAnchor.constraint(equalToConstant: 20)
    badgeLabelHeightConstraint?.isActive = true
    badgeLabel.layer.cornerRadius = 10
    
    rightStackView.autoPinEdge(.top, to: .bottom, of: badgeLabel)
    rightStackView.autoPinEdge(toSuperviewEdge: .trailing, withInset: 15)
    rightStackView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 10)
    rightStackView.autoPinEdge(.leading, to: .trailing, of: leftStackView, withOffset: 20)
    rightStackView.widthAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
  }
  
  private func configureBadgeLabel(text: String?) {
    let isTextNil = text == nil
    badgeLabel.text = isTextNil ? nil : text
    badgeLabelWidthConstraint?.constant = isTextNil ? 0 : badgeLabel.intrinsicContentSize.width + (2 * 10)
    badgeLabelHeightConstraint?.constant = isTextNil ? 0 : 20
    distanceLabel.isHidden = !isTextNil
    postalCodeLabel.isHidden = !isTextNil
  }
  
  private func configureBorder(for type: NYPLLibraryFinderLibraryCellType) {
    layer.cornerRadius = NYPLLibraryFinderConfiguration.cellCornerRadius(type: type)
    switch type {
    case .myLibrary:
      layer.borderWidth = 0.0
      divider.isHidden = false
    case .newLibrary:
      layer.removeCustomBorders()
      layer.borderWidth = NYPLLibraryFinderConfiguration.borderWidth
      layer.borderColor = NYPLLibraryFinderConfiguration.borderColor.cgColor
      divider.isHidden = true
    }
  }
  
  private func updateBorder() {
    if type == .myLibrary {
      layer.removeCustomBorders()
      layer.addBorder(side: .leftAndRight,
                      thickness: NYPLLibraryFinderConfiguration.borderWidth,
                      color: NYPLLibraryFinderConfiguration.borderColor.cgColor)
    } else {
      layer.borderColor = NYPLLibraryFinderConfiguration.borderColor.cgColor
    }
  }
  
  // MARK: - UI Components
  
  private lazy var divider: UIView = {
    let view = UIView()
    view.backgroundColor = NYPLLibraryFinderConfiguration.borderColor
    addSubview(view)
    return view
  }()
  
  private lazy var leftStackView: UIStackView = {
    let stackView = UIStackView(arrangedSubviews: [nameLabel, descriptionLabel])
    stackView.axis = .vertical
    stackView.spacing = stackViewSpacing
    stackView.alignment = .leading
    addSubview(stackView)
    return stackView
  }()
  
  private lazy var rightStackView: UIStackView = {
    let stackView = UIStackView(arrangedSubviews: [distanceLabel, postalCodeLabel, UIView()])
    stackView.axis = .vertical
    stackView.spacing = stackViewSpacing
    stackView.alignment = .trailing
    addSubview(stackView)
    return stackView
  }()
  
  private lazy var badgeLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .center
    label.font = UIFont.systemFont(ofSize: 12)
    label.textColor = .white
    label.backgroundColor = .purple
    label.clipsToBounds = true
    addSubview(label)
    return label
  }()
  
  private lazy var nameLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 18)
    label.numberOfLines = 0
    return label
  }()
  
  private lazy var descriptionLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 12, weight: .light)
    label.numberOfLines = 0
    return label
  }()
  
  private lazy var distanceLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 12)
    return label
  }()
  
  private lazy var postalCodeLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 12)
    return label
  }()
}
