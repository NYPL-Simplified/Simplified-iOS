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

  /// Use this convenience initializer only if calling from ObjC or R1 context.
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
    configR2Fonts()
  }

  /// Get associated colors for a specific appearance setting.
  /// - parameter appearance: The selected appearance.
  /// - Returns: A tuple with a background color and a text color.
  static func colors(for appearance: UserProperty) -> (backgroundColor: UIColor, textColor: UIColor) {
    var backgroundColor, textColor: UIColor

    switch appearance.toString() {
    case "readium-sepia-on":
      backgroundColor = NYPLConfiguration.readerBackgroundSepiaColor()
      textColor = UIColor.black
    case "readium-night-on":
      backgroundColor = NYPLConfiguration.readerBackgroundDarkColor()
      textColor = UIColor.white
    default:
      backgroundColor = UIColor.white
      textColor = UIColor.black
    }

    return (backgroundColor, textColor)
  }

  /// Persists both R1 and R2 user settings.
  func save() {
    r1UserSettings.save()
    r2UserSettings?.save()
  }

  var backgroundColor: UIColor {
    return r1UserSettings.backgroundColor
  }

  /// The setter sets the color scheme in both R1 and R2 user reader settings.
  /// - Note: This does not persist the change. Call `save()` for that.
  var colorScheme: NYPLReaderSettingsColorScheme {
    get {
      // on app versions w/ R2 (SE 3.7.0+, OE 2.0+), R1 and R2 settings match.
      // on older app versions, the R1 setting will be the only available one.
      return r1UserSettings.colorScheme
    }

    set {
      r1UserSettings.colorScheme = newValue

      if let appearance = r2UserSettings?.userProperties.getProperty(reference: ReadiumCSSReference.appearance.rawValue) as? Enumerable {
        appearance.index = newValue.rawValue
      }
    }
  }

  /// The setter sets the font family to be used in both R1 and R2 user settings.
  /// - Note: This does not persist the change. Call `save()` for that.
  var fontFace: NYPLReaderSettingsFontFace {
    get {
      // on app versions w/ R2 (SE 3.7.0+, OE 2.0+), R1 and R2 settings match.
      // on older app versions, the R1 setting will be the only available one.
      return r1UserSettings.fontFace
    }

    set {
      // ensure we keep R1 in sync with R2
      r1UserSettings.fontFace = newValue

      let fontFamily = r2UserSettings?.userProperties.getProperty(reference: ReadiumCSSReference.fontFamily.rawValue) as? Enumerable
      let fontOverride = r2UserSettings?.userProperties.getProperty(reference: ReadiumCSSReference.fontOverride.rawValue) as? Switchable

      if let fontFamily = fontFamily {
        // we don't use the "Original" font, so we add 1 to the chosen index
        fontFamily.index = newValue.rawValue + 1
        if let fontOverride = fontOverride {
          // if we had to use the Original font, we would need to set the
          // `fontOverride.on` setting to false. Since in our use case this is
          // never true, we can just set it to true.
          fontOverride.on = true
        }
      }
    }
  }

  var fontSize: NYPLReaderSettingsFontSize {
    // R1 and R2 settings are always kept in sync
    return r1UserSettings.fontSize
  }

  /// Modifies the value of the font size according to the specified `change`.
  /// - Parameters:
  ///   - fontSize: The old font size.
  ///   - change: How the `fontSize` should be changed.
  /// - Returns: The new font size.
  /// - Note: This does not persist the change.
  func modifyFontSize(fromOldValue fontSize: NYPLReaderSettingsFontSize,
                      effectuating change: NYPLReaderFontSizeChange) -> NYPLReaderSettingsFontSize {
    //  R1
    var newSize = fontSize
    let r1Changed: Bool = {
      switch change {
      case .increase:
        return NYPLReaderSettingsIncreasedFontSize(fontSize,
                                                   &newSize)
      case .decrease:
        return NYPLReaderSettingsDecreasedFontSize(fontSize,
                                                   &newSize)
      }
    }()
    if r1Changed {
      r1UserSettings.fontSize = newSize
    }

    // R2
    // we always modify the R2 value because we don't have a way to understand
    // that if a book was already downloaded and partially read with R1 but
    // never displayed in R2, we still need a way to set the R2 value
    modifyR2FontSize(fromR1: newSize)

    return newSize
  }

  // MARK: - Private

  /// Converts the R1 value for font size into something that R2 can understand
  /// and applies that value to the related R2 user setting.
  /// - Parameter r1Value: The font size value as it comes from R1.
  private func modifyR2FontSize(fromR1 r1Value: NYPLReaderSettingsFontSize) {
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

  private func configR2Fonts() {
    // before removing the default fontFamily set up by R2Streamer, we should
    // read the current user selection from NSUserDefaults so we can apply it
    // to our new set-up
    let fontFamily = r2UserSettings?.userProperties.getProperty(reference: ReadiumCSSReference.fontFamily.rawValue) as? Enumerable
    let currentFontfamily: Int
    if let fontFamily = fontFamily {
      currentFontfamily = fontFamily.index
    } else {
      currentFontfamily = 1
    }

    // this wipes out the default R2Streamer font families
    r2UserSettings?.userProperties.removeProperty(forReference: ReadiumCSSReference.fontFamily)

    // "Original" represents the publication's default font. Even if we don't
    // use it, it _must_ be present as the first value.
    r2UserSettings?.userProperties
      .addEnumerable(index: currentFontfamily,
                     values: ["Original", "Helvetica", "Georgia", "OpenDyslexic"],
                     reference: ReadiumCSSReference.fontFamily.rawValue,
                     name: ReadiumCSSName.fontFamily.rawValue)
  }
}

// MARK: -

public extension UserProperties {
  /// Removes a property matching a CSS reference.
  /// - Parameter ref: The CSS reference of the property to be removed.
  func removeProperty(forReference ref: ReadiumCSSReference) {
    properties.removeAll {
      $0.reference == ref.rawValue
    }
  }
}
