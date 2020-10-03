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

    return fallback(forURLType: urlType)
  }
}


