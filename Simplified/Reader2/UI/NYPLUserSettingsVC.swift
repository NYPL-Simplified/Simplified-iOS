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
    let view = NYPLReaderSettingsView(width: 300)
    view.delegate = self

    view.colorScheme = userSettings.colorScheme
    view.fontSize = userSettings.fontSize
    view.fontFace = userSettings.fontFace
    view.backgroundColor = userSettings.backgroundColor
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
    userSettings.colorScheme = colorScheme
    userSettings.save()
    delegate?.applyCurrentSettings()
  }

  func readerSettingsView(_ settingsView: NYPLReaderSettingsView,
                          didChangeFontSize change: NYPLReaderFontSizeChange) -> NYPLReaderSettingsFontSize {

    let newSize = userSettings.modifyFontSize(fromOldValue: settingsView.fontSize,
                                              effectuating: change)
    userSettings.save()
    delegate?.applyCurrentSettings()

    return newSize
  }

  func readerSettingsView(_ readerSettingsView: NYPLReaderSettingsView,
                          didSelect fontFace: NYPLReaderSettingsFontFace) {
    userSettings.fontFace = fontFace
    userSettings.save()
    delegate?.applyCurrentSettings()
  }
}
