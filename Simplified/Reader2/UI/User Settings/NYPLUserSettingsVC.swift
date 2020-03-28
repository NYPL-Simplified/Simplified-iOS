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

  /// Apply the user settings to the reader screen
  func applyCurrentSettings()

  /// Obtain the current user settings
  var userSettings: NYPLR1R2UserSettings { get }

  /// Only used by R2-related code to update the appearance.
  /// - Parameter appearanceIndex: Value corresponding to a UserProperty index
  /// property for the appearance settings.
  /// - TODO: SIMPLY-2604
  func setUIColor(forR2 appearanceIndex: Int)
}

//==============================================================================

/// A view controller to handle the logic related to the user settings UI
/// events described by `NYPLReaderSettingsViewDelegate`. This class takes care
/// of translating those UI events into changes to both Readium 1 and Readium 2
/// systems, which handle user settings in different / incompatible ways.
/// The "output" of this class is to eventually call
@objc class NYPLUserSettingsVC: UIViewController {

  weak var delegate: NYPLUserSettingsReaderDelegate?
  var userSettings: NYPLR1R2UserSettings?

  /// The designated initializer.
  /// - Parameter delegate: The object responsible to handle callbacks in
  /// response to User Settings UI changes.
  @objc init(delegate: NYPLUserSettingsReaderDelegate) {
    super.init(nibName: nil, bundle: nil)
    self.delegate = delegate
    self.userSettings = delegate.userSettings
  }

  /// Instantiting this class in a xib/storyboard is not supported.
  required init?(coder: NSCoder) {
    fatalError("init(coder:) not implemented")
  }

  override func loadView() {
    let view = NYPLReaderSettingsView(width: 300)
    view.delegate = self
    view.colorScheme = NYPLReaderSettings.shared().colorScheme
    view.fontSize = NYPLReaderSettings.shared().fontSize
    view.fontFace = NYPLReaderSettings.shared().fontFace
    view.backgroundColor = NYPLReaderSettings.shared().backgroundColor
    self.view = view;
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.preferredContentSize = self.view.bounds.size
  }
}

// MARK: - NYPLReaderSettingsViewDelegate

extension NYPLUserSettingsVC: NYPLReaderSettingsViewDelegate {
  func readerSettingsView(_ readerSettingsView: NYPLReaderSettingsView,
                          didSelectBrightness brightness: CGFloat) {
    UIScreen.main.brightness = brightness
  }

  func readerSettingsView(_ readerSettingsView: NYPLReaderSettingsView,
                          didSelect colorScheme: NYPLReaderSettingsColorScheme) {
    userSettings?.r1UserSettings.colorScheme = colorScheme
    delegate?.applyCurrentSettings()
  }

  func readerSettingsView(_ settingsView: NYPLReaderSettingsView,
                          didChangeFontSize change: NYPLReaderFontSizeChange) -> NYPLReaderSettingsFontSize {
    //  R1
    var newSize = settingsView.fontSize
    let r1Changed = NYPLReaderSettingsIncreasedFontSize(settingsView.fontSize,
                                                      &newSize)
    if r1Changed {
      userSettings?.r1UserSettings.fontSize = newSize
    }

    // R2
    if let fontSize = userSettings?.r2UserSettings?.userProperties.getProperty(reference: ReadiumCSSReference.fontSize.rawValue) as? Incrementable {

      // Note, R2's `increment`/`decrement` functions do bound checks, so e.g.
      // calling `increment` when fontSize is already the max results in a no-op
      switch change {
      case .increase:
        fontSize.increment()
      case .decrease:
        fontSize.decrement()
      }

      delegate?.applyCurrentSettings()
    } else if r1Changed {
      delegate?.applyCurrentSettings()
    }

    return newSize
  }

  func readerSettingsView(_ readerSettingsView: NYPLReaderSettingsView,
                          didSelect fontFace: NYPLReaderSettingsFontFace) {
    userSettings?.r1UserSettings.fontFace = fontFace
    delegate?.applyCurrentSettings()
  }

  func readerSettingsView(_ readerSettingsView: NYPLReaderSettingsView,
                          didSelect flag: NYPLReaderSettingsMediaOverlaysEnableClick) {
    userSettings?.r1UserSettings.mediaOverlaysEnableClick = flag
    delegate?.applyCurrentSettings()
  }
}
