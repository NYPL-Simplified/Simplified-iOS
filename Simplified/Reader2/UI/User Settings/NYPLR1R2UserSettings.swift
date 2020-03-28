//
//  NYPLR1R2UserSettings.swift
//  SimplyE
//
//  Created by Ettore Pasquini on 3/27/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation
import R2Navigator

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

//  /// Converts the R2 font size value to a R1 value we can use in SimplyE.
//  func r1FontSize() -> NYPLReaderSettingsFontSize {
//    guard let r2FontSize = r2UserSettings?.userProperties.getProperty(reference: ReadiumCSSReference.fontSize.rawValue) as? Incrementable else {
//      return .normal
//    }
//
//    // R2 values may reach the bounds min / max values
//    let r2Range = r2FontSize.max - r2FontSize.min
//
//    // convert R2 value inside the [0...1] range
//    let percValue: Float = {
//      let val = (r2FontSize.value - r2FontSize.min)
//      if val < 0 {
//        return r2FontSize.min
//      }
//      return val / r2Range
//    }()
//
//    // range between 0...7 inclusive
//    let r1Range = Float(NYPLReaderSettingsFontSizeMaxValue)
//    let r1Value = Int(round(percValue * r1Range))
//
//    // sanity check
//    if r1Value > NYPLReaderSettingsFontSize.xxxLarge.rawValue {
//      return NYPLReaderSettingsFontSize.xxxLarge
//    }
//
//    return NYPLReaderSettingsFontSize(rawValue: r1Value) ?? .normal
//  }
}
