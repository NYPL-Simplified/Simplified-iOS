//
//  NYPLUserSettingsVC.swift
//  SimplyE
//
//  Created by Ettore Pasquini on 3/26/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import UIKit
import R2Shared
import R2Navigator

//==============================================================================

/// This protocol describes the interface necessary to the UserSettings UI code
/// to interact with a reader system. This protocol can be used for both
/// Readium 1 or Readium 2.
@objc protocol NYPLUserSettingsReaderDelegate: NSObjectProtocol {

  /// Apply all the current user settings to the reader screen.
  func applyCurrentSettings()

  /// Obtain the current user settings.
  var userSettings: NYPLR1R2UserSettings { get }
}

//==============================================================================

/// A view controller to handle the logic related to the user settings UI
/// events described by `NYPLReaderSettingsViewDelegate`. This class takes care
/// of translating those UI events into changes to both Readium 1 and Readium 2
/// systems, which handle user settings in different / incompatible ways.
/// The "output" of this class is to eventually call
@objc class NYPLUserSettingsVC: UIViewController {

  weak var delegate: NYPLUserSettingsReaderDelegate?
  let userSettings: NYPLR1R2UserSettings
  private var didUpdateContentSize: Bool = false

  /// The designated initializer.
  /// - Parameter delegate: The object responsible to handle callbacks in
  /// response to User Settings UI changes.
  @objc init(delegate: NYPLUserSettingsReaderDelegate) {
    self.delegate = delegate
    self.userSettings = delegate.userSettings
    super.init(nibName: nil, bundle: nil)
  }

  /// Instantiting this class in a xib/storyboard is not supported.
  required init?(coder: NSCoder) {
    fatalError("init(coder:) not implemented")
  }
  
  override func loadView() {
    let width: CGFloat = 300
    let view = NYPLReaderSettingsView(width: width,
                                      colorScheme: userSettings.colorScheme,
                                      fontSize: userSettings.fontSize,
                                      fontFace: userSettings.fontFace,
                                      publisherDefault: userSettings.publisherDefault)
    view.delegate = self
    // The superview of this view controller sets a auto resizing constraint
    // if it does not know the size of this view. At this point, the NYPLReaderSettingsView
    // has not been lay out, so we are using an estimated size to avoid the constraint being created.
    self.preferredContentSize = .init(width: width, height: 400)
    self.view = view
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    if !didUpdateContentSize {
      // We are updating the content size here because
      // 1) NYPLReaderSettingsView is laid out and size is now known
      // 2) User will not see the awkward changes of the view
      let contentSize = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
      self.preferredContentSize = contentSize
      
      if let view = self.view as? NYPLReaderSettingsView {
        view.updateUI()
      }
      
      didUpdateContentSize = true
    }
  }
}

// MARK: - NYPLReaderSettingsViewDelegate

extension NYPLUserSettingsVC: NYPLReaderSettingsViewDelegate {
  func didSelectBrightness(_ brightness: CGFloat) {
    UIScreen.main.brightness = brightness
  }
  
  func didSelectColorScheme(_ colorScheme: NYPLReaderSettingsColorScheme) {
    userSettings.colorScheme = colorScheme
    userSettings.save()
    delegate?.applyCurrentSettings()
  }
  
  func settingsView(_ view: NYPLReaderSettingsView,
                    didChangeFontSize change: NYPLReaderFontSizeChange) -> NYPLReaderSettingsFontSize {
    let newSize = userSettings.modifyFontSize(fromOldValue: view.fontSize,
                                              effectuating: change)
    userSettings.save()
    delegate?.applyCurrentSettings()

    return newSize
  }
  
  func didSelectFontFace(_ fontFace: NYPLReaderSettingsFontFace) {
    userSettings.fontFace = fontFace
    userSettings.save()
    delegate?.applyCurrentSettings()
  }
  
  func didChangePublisherDefaults(_ isEnabled: Bool) {
    userSettings.publisherDefault = isEnabled
    userSettings.save()
    delegate?.applyCurrentSettings()
  }
}
