//
//  NYPLURLSettingsProviderMock.swift
//  Simplified
//
//  Created by Ettore Pasquini on 10/14/20.
//  Copyright © 2020 NYPL. All rights reserved.
//

import Foundation
@testable import SimplyE

class NYPLURLSettingsProviderMock: NSObject, NYPLUniversalLinksSettings, NYPLFeedURLProvider {
  var accountMainFeedURL: URL?

  var universalLinksURL: URL {
    return URL(string: "https://example.com/univeral-link-redirect")!
  }
}

