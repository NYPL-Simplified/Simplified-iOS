//
//  NYPLRoundedButton.swift
//  Simplified
//
//  Created by Ernest Fan on 2021-03-31.
//  Copyright © 2021 NYPL. All rights reserved.
//

import UIKit

private let NYPLRoundedButtonPadding: CGFloat = 6.0

@objc enum NYPLRoundedButtonType: Int {
  case normal
  case clock
}

@objc class NYPLRoundedButton: UIButton {
  // Properties
  private var type: NYPLRoundedButtonType {
    didSet {
      updateViews()
    }
  }
  private var endDate: Date? {
    didSet {
      updateViews()
    }
  }
  private var isFromDetailView: Bool
  
  // UI Components
  private let label: UILabel = UILabel()
  private let iconView: UIImageView = UIImageView()
  
  // Initializer
  init(type: NYPLRoundedButtonType, endDate: Date?, isFromDetailView: Bool) {
    self.type = type
    self.endDate = endDate
    self.isFromDetailView = isFromDetailView
    
    super.init(frame: CGRect.zero)
    
    setupUI()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Setter
  @objc func setType(_ type: NYPLRoundedButtonType) {
    self.type = type
  }
  
  @objc func setEndDate(_ date: NSDate?) {
    guard let convertedDate = date as Date? else {
      return
    }
    endDate = convertedDate
  }
  
  @objc func setFromDetailView(_ isFromDetailView: Bool) {
    self.isFromDetailView = isFromDetailView
  }
  
  // MARK: - UI
  private func setupUI() {
    titleLabel?.font = UIFont.systemFont(ofSize: 14)
    layer.borderColor = tintColor.cgColor
    layer.borderWidth = 1
    layer.cornerRadius = 3
    
    label.textColor = self.tintColor
    label.font = UIFont.systemFont(ofSize: 9)
    
    addSubview(label)
    addSubview(iconView)
  }
  
  private func updateViews() {
    let padX = NYPLRoundedButtonPadding + 2
    let padY = NYPLRoundedButtonPadding
    
    if (self.type == .normal || self.isFromDetailView) {
      if isFromDetailView {
        self.contentEdgeInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20)
      } else {
        self.contentEdgeInsets = UIEdgeInsets(top: padY, left: padX, bottom: padY, right: padX)
      }
      self.iconView.isHidden = true
      self.label.isHidden = true
    } else {
      self.iconView.image = UIImage.init(named: "Clock")?.withRenderingMode(.alwaysTemplate)
      self.iconView.isHidden = false
      self.label.isHidden = false
      self.label.text = self.endDate?.timeUntilString(suffixType: .short) ?? ""
      self.label.sizeToFit()
      
      self.iconView.frame = CGRect(x: padX, y: padY/2, width: 14, height: 14)
      var frame = self.label.frame
      frame.origin = CGPoint(x: self.iconView.center.x - frame.size.width/2, y: self.iconView.frame.maxY)
      self.label.frame = frame
      self.contentEdgeInsets = UIEdgeInsets(top: padY, left: self.iconView.frame.maxX + padX, bottom: padY, right: padX)
    }
  }
  
  private func updateColors() {
    let color: UIColor = self.isEnabled ? self.tintColor : UIColor.gray
    self.layer.borderColor = color.cgColor
    self.label.textColor = color
    self.iconView.tintColor = color
    setTitleColor(color, for: .normal)
  }
  
  // Override UIView functions
  override var isEnabled: Bool {
    didSet {
      updateColors()
    }
  }
  
  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    if (!self.isEnabled
      && self.point(inside: self.convert(point, to: self), with: event)) {
      return self
    }
    return super.hitTest(point, with: event)
  }
  
  override func sizeThatFits(_ size: CGSize) -> CGSize {
    var s = super.sizeThatFits(size)
    s.width += NYPLRoundedButtonPadding * 2
    return s
  }
  
  override func tintColorDidChange() {
    super.tintColorDidChange()
    updateColors()
  }
  
  private var customAccessibilityLabel: String?
  
  // The button label will be the customAccessibilityLabel for one time if it is not nil.
  // After that, the button label will be the regular accessibility label.
  override var accessibilityLabel: String? {
    get {
      if let label = customAccessibilityLabel {
        self.customAccessibilityLabel = nil
        return label
      }
      return self.titleLabel?.text
    }
    set {
      self.customAccessibilityLabel = newValue
    }
  }
  
  @objc var timeRemainingString: String? {
    guard let timeUntilString = self.endDate?.timeUntilString(suffixType: .long) else {
      return nil
    }
    return "\(timeUntilString) remaining."
  }
}

extension NYPLRoundedButton {
  @objc (initWithType:isFromDetailView:)
  convenience init(type: NYPLRoundedButtonType, isFromDetailView: Bool) {
    self.init(type: type, endDate: nil, isFromDetailView: isFromDetailView)
  }
}
