//
//  NYPLConfiguration.swift
//  Simplified
//
//  Created by Ettore Pasquini on 6/3/22.
//  Copyright © 2022 NYPL. All rights reserved.
//

import UIKit

class NYPLConfiguration: NSObject {
  private override init() {
    super.init()
  }

  // MARK: - Objects

  static var mainFeedURL: URL? {
    if let customURL = NYPLSettings.shared.customMainFeedURL {
      return customURL
    }

    return NYPLSettings.shared.accountMainFeedURL
  }

  // MARK: - Colors

  @objc static var accentColor: UIColor {
    return UIColor(red: 0.0/255.0, green: 144/255.0, blue: 196/255.0, alpha:1.0)
  }

  @objc static var readerBackgroundColor: UIColor {
    return UIColor(white: 250/255.0, alpha:1.0)
  }

  // OK to leave as static color because it's reader-only
  @objc static var readerBackgroundDarkColor: UIColor {
    return UIColor(white: 5/255.0, alpha:1.0)
  }

  // OK to leave as static color because it's reader-only
  @objc static var readerBackgroundSepiaColor: UIColor {
    return UIColor(red: 250/255.0, green: 244/255.0, blue: 232/255.0, alpha: 1.0)
  }

  // OK to leave as static color because it's reader-only
  @objc static var backgroundMediaOverlayHighlightColor: UIColor {
    return .yellow
  }

  // OK to leave as static color because it's reader-only
  @objc static var backgroundMediaOverlayHighlightDarkColor: UIColor {
    return .orange
  }

  // OK to leave as static color because it's reader-only
  @objc static var backgroundMediaOverlayHighlightSepiaColor: UIColor {
    return .yellow
  }

  // MARK: - Fonts

  // Set for the whole app via UIView+NYPLFontAdditions.
  @objc static var systemFontName: String {
    return "AvenirNext-Medium"
  }

  // Set for the whole app via UIView+NYPLFontAdditions.
  static var boldSystemFontName: String {
    return "AvenirNext-Bold"
  }

  @objc static var systemFontFamilyName: String {
    return "Avenir Next"
  }

  //MARK: - Dimensions

  static var defaultTOCRowHeight: CGFloat {
    return 56
  }

  static var defaultBookmarkRowHeight: CGFloat {
    return 100
  }

  static var cornerRadius: CGFloat {
    return 5
  }
}
