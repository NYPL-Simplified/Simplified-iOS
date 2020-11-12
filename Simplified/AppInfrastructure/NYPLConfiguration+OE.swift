//
//  NYPLConfiguration+OE.swift
//  Open eBooks
//
//  Created by Ettore Pasquini on 9/9/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

extension NYPLConfiguration {
  /// The only "library" account ID that Open eBooks will ever handle.
  static let OpenEBooksUUID = "urn:uuid:e1a01c16-04e7-4781-89fd-b442dd1be001"

  static let circulationBaseURLProduction = "https://circulation.openebooks.us"
  static let circulationBaseURLBeta = "http://qa-circulation.openebooks.us"
  static let circulationURL = URL(string: circulationBaseURLProduction)!

  static let openEBooksRequestCodesURL = URL(string: "http://openebooks.net/getstarted.html")!

  private static let feedFileUrl = URL(fileURLWithPath:
    Bundle.main.path(forResource: "OpenEBooks_OPDS2_Catalog_Feed",
                     ofType: "json")!)
  private static let feedFileUrlHash = feedFileUrl.absoluteString.md5().base64EncodedStringUrlSafe().trimmingCharacters(in: ["="])

  static let betaUrl = feedFileUrl
  static var prodUrl = feedFileUrl

  static var betaUrlHash = feedFileUrlHash
  static var prodUrlHash = feedFileUrlHash

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
}
