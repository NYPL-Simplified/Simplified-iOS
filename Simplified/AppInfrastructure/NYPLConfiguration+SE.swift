//
//  NYPLConfiguration+SE.swift
//  Simplified
//
//  Created by Ettore Pasquini on 9/9/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

extension NYPLConfiguration {

  static let betaUrl = URL(string: "https://libraryregistry.librarysimplified.org/libraries/qa")!
  static let prodUrl = URL(string: "https://libraryregistry.librarysimplified.org/libraries")!

  static let betaUrlHash = betaUrl.absoluteString.md5().base64EncodedStringUrlSafe().trimmingCharacters(in: ["="])
  static let prodUrlHash = prodUrl.absoluteString.md5().base64EncodedStringUrlSafe().trimmingCharacters(in: ["="])

  @objc static func mainColor() -> UIColor {
    if #available(iOS 12.0, *),
       UIScreen.main.traitCollection.userInterfaceStyle == UIUserInterfaceStyle.dark {
      return NYPLConfiguration.actionColor
    }
    
    let libAccount = AccountsManager.sharedInstance().currentAccount
    if let mainColor = libAccount?.details?.mainColor {
      return NYPLAppTheme.themeColorFromString(name: mainColor)
    }
    return UIColor.black
  }

  @objc static func iconLogoBlueColor() -> UIColor {
    if #available(iOS 13, *) {
      if let color = UIColor(named: "ColorIconLogoBlue") {
        return color
      }
    }

    return UIColor(red: 17.0/255.0, green: 50.0/255.0, blue: 84.0/255.0, alpha: 1.0)
  }

  @objc static func iconLogoGreenColor() -> UIColor {
    return UIColor(red: 141.0/255.0, green: 199.0/255.0, blue: 64.0/255.0, alpha: 1.0)
  }

  static func cardCreationEnabled() -> Bool {
    return true
  }
}
