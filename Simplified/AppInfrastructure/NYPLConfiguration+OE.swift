//
//  NYPLConfiguration+OE.swift
//  Open eBooks
//
//  Created by Ettore Pasquini on 9/9/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

extension NYPLConfiguration {
  // MARK:- Prod library catalog

  /// The only "library" ID that Open eBooks will ever handle (beside beta).
  /// This value is taken from `OpenEBooks_OPDS2_Library_Registry_Feed.json`.
  static let OpenEBooksUUIDProd = "urn:uuid:e1a01c16-04e7-4781-89fd-b442dd1be001"

  private static let feedFileUrl = URL(fileURLWithPath:
    Bundle.main.path(forResource: "OpenEBooks_OPDS2_Library_Registry_Feed",
                     ofType: "json")!)
  private static let prodFeedKey = "OpenEBooksLibraryRegistryProdFeedKey"
  
  static var prodUrl = feedFileUrl
  static let prodFeedKeyHash = prodFeedKey.md5().base64EncodedStringUrlSafe().trimmingCharacters(in: ["="])

  // MARK:- Beta library catalog

  /// This value is taken from `OpenEBooks_OPDS2_Library_Registry_Feed-QA.json`.
  static let OpenEBooksUUIDBeta = "urn:uuid:e1a01c16-04e7-4781-89fd-b442dd1be666"
  private static let betaFeedFileUrl = URL(fileURLWithPath:
    Bundle.main.path(forResource: "OpenEBooks_OPDS2_Library_Registry_Feed-QA",
                     ofType: "json")!)
  private static let betaFeedKey = "OpenEBooksLibraryRegistryBetaFeedKey"

  static var betaUrl = betaFeedFileUrl
  static let betaFeedKeyHash = betaFeedKey.md5().base64EncodedStringUrlSafe().trimmingCharacters(in: ["="])

  // MARK:-

  static let openEBooksRequestCodesURL = URL(string: "http://openebooks.net/getstarted.html")!

  @objc static func mainColor() -> UIColor {
    return UIColor(red: 141.0/255.0, green: 199.0/255.0, blue: 64.0/255.0, alpha: 1.0)
  }

  static var welcomeTutorialBackgroundColor: UIColor {
    if #available(iOS 11.0, *) {
      if let color = UIColor(named: "TutorialColor") {
        return color
      }
    }

    return .white
  }

  static func cardCreationEnabled() -> Bool {
    return false
  }

  static func welcomeScreenFont() -> UIFont? {
    if UIDevice.current.userInterfaceIdiom == .phone {
      return UIFont(name: NYPLConfiguration.systemFontFamilyName(),
                    size: 18.0)
    }
    return UIFont(name: NYPLConfiguration.systemFontFamilyName(), size: 22.0)
  }
}
