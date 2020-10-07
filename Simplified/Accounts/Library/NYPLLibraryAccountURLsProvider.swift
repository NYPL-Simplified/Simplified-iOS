//
//  NYPLLibraryAccountURLsProvider.swift
//  Open eBooks
//
//  Created by Ettore Pasquini on 9/30/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

class NYPLLibraryAccountURLsProvider {
  private let account: Account?

  init(account: Account?) {
    self.account = account
  }

  func accountURL(forType urlType: URLType) -> URL {
    if let url = account?.details?.getLicenseURL(urlType) {
      return url
    }

    // provide some reasonable defaults if we can't find a URL
    switch urlType {
    case .acknowledgements:
      return URL(string: "https://openebooks.net/app_acknowledgments.html")!
    case .eula:
      return URL(string: "https://openebooks.net/app_user_agreement.html")!
    case .privacyPolicy:
      return URL(string: "https://openebooks.net/app_privacy.html")!
    default:
      // should never happen for OE
      return URL(string: "https://openebooks.net")!
    }
  }
}

