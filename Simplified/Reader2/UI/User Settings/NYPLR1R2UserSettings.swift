//
//  NYPLR1R2UserSettings.swift
//  SimplyE
//
//  Created by Ettore Pasquini on 3/27/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation
import R2Navigator
import R2Shared

/// Wrapper class for Readium 1 and Readium 2 reader user settings.
class NYPLR1R2UserSettings: NSObject {
  @objc let r1UserSettings: NYPLReaderSettings
  let r2UserSettings: UserSettings?

  /// Use this convenience initializer only if calling from ObjC.
  @objc override convenience init() {
    self.init(r2UserSettings: nil)
  }

  /// Designated initializer.
  /// - Parameter r2UserSettings: Readium 2 user settings. This typically comes
  /// from the R2Navigator classes such as EPUBNavigatorViewController.
  init(r2UserSettings: UserSettings?) {
    self.r1UserSettings = NYPLReaderSettings.shared()
    self.r2UserSettings = r2UserSettings
    super.init()
  }

  /// Converts the R1 value for font size into something that R2 can understand
  /// and applies that value to the related R2 user setting.
  /// - Parameter r1Value: The font size value as it comes from R1.
  func modifyR2FontSize(fromR1 r1Value: NYPLReaderSettingsFontSize) {
    guard let r2FontSize = r2UserSettings?.userProperties.getProperty(reference: ReadiumCSSReference.fontSize.rawValue) as? Incrementable else {
      return
    }

    // convert R1 value into the [0...1] range
    let r1Range = Float(NYPLReaderSettingsFontSize.largest.rawValue - NYPLReaderSettingsFontSize.smallest.rawValue)
    let percValue = Float(r1Value.rawValue - NYPLReaderSettingsFontSize.smallest.rawValue) / r1Range

    // convert the percentage range into R2
    let r2Range = r2FontSize.max - r2FontSize.min
    r2FontSize.value = r2FontSize.min + percValue * r2Range
  }

  /// Persists both R1 and R2 user settings.
  func save() {
    r1UserSettings.save()
    r2UserSettings?.save()
  }
}
