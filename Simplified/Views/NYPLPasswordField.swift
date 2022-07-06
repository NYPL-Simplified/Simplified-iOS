//
//  NYPLPasswordField.swift
//  Open eBooks
//
//  Created by Ettore Pasquini on 7/6/22.
//  Copyright © 2022 NYPL. All rights reserved.
//

import UIKit
import PureLayout


@IBDesignable
/// A UITextField subclass for passwords that adds a button to reveal the
/// password text.
///
/// The image of the reveal button is configurable either in Interface Builder
/// or via a provided initializer.
open class NYPLPasswordField: UITextField {
  let eyeButton: UIButton
  private var eyeConstraintWidth: NSLayoutConstraint?
  private var eyeConstraintHeight: NSLayoutConstraint?

  // MARK: - Initialization

  required public init?(coder: NSCoder) {
    eyeButton = UIButton(type: .custom)
    super.init(coder: coder)
    commonInit()
  }

  /// Initialize the view in code with a custom "eye" image to reveal the
  /// password.
  ///
  /// - Parameters:
  ///   - frame: The frame for the view.
  ///   - eyeImage: The image of the button that reveals the password text.
  public init(frame: CGRect, eyeImage: UIImage?) {
    eyeButton = UIButton(type: .custom)
    eyeButton.setImage(eyeImage, for: .normal)
    super.init(frame: frame)
    commonInit()
  }

  private func commonInit() {
    if #available(iOS 11, *) {
      self.textContentType = .password
    }
    self.isSecureTextEntry = true
    addTarget(self, action: #selector(textDidChange), for: .editingChanged)

    eyeButton.contentMode = .scaleAspectFit
    eyeButton.addTarget(self, action: #selector(eyePressed), for: .touchUpInside)
    addSubview(eyeButton)
    eyeButton.autoAlignAxis(.horizontal, toSameAxisOf: self, withOffset: 0)
    eyeButton.autoPinEdge(toSuperviewEdge: .right, withInset: 10)
    updateImageConstraints()
  }

  // MARK: - Update

  override open var font: UIFont? {
    get {
      return super.font
    }
    set {
      super.font = newValue
      updateImageConstraints()
    }
  }

  private func updateImageConstraints() {
    guard let eyeHeight = font?.pointSize else {
      return
    }

    guard let eyeSize = eyeButton.image(for: .normal)?.size else {
      return
    }

    let aspectRatio = eyeSize.width / eyeSize.height
    let eyeWidth = eyeHeight * aspectRatio

    if eyeConstraintWidth == nil {
      eyeConstraintWidth = eyeButton.autoSetDimension(.width,
                                                      toSize: eyeWidth)
    } else {
      eyeConstraintWidth?.constant = eyeWidth
    }

    if eyeConstraintHeight == nil {
      eyeConstraintHeight = eyeButton.autoSetDimension(.height,
                                                       toSize: eyeHeight)
    } else {
      eyeConstraintHeight?.constant = eyeHeight
    }

    bringSubviewToFront(eyeButton)
  }

  // MARK: - Event handling

  @objc func textDidChange() {
    // this is required otherwise the eye button becomes no longer clickable
    // once the user starts entering text
    bringSubviewToFront(eyeButton)
  }

  @objc func eyePressed() {
    isSecureTextEntry.toggle()
  }

  // MARK: - Interface Builder Helpers

  @IBInspectable public var eyeImage: UIImage? {
    get {
      return eyeButton.image(for: .normal)
    }
    set {
      eyeButton.setImage(newValue, for: .normal)
      updateImageConstraints()
    }
  }

  override open func prepareForInterfaceBuilder() {
    super.prepareForInterfaceBuilder()
    commonInit()
  }
}
