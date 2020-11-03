//
//  NYPLUniversalLinksSettingsMock.swift
//  Simplified
//
//  Created by Ettore Pasquini on 10/14/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation
@testable import SimplyE

class NYPLUniversalLinksSettingsMock: NSObject, NYPLUniversalLinksSettings {
  var authenticationUniversalLink: URL {
    return URL(string: "https://example.com/univeral-link-redirect")!
  }
}

