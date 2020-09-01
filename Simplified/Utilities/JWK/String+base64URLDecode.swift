//
//  String+base64URLDecode.swift
//  SimplyE
//
//  Created by Vladimir Fedorov on 31.08.2020.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

extension String {
  /// Decodes base64-encoded URL-friendly string to data. JWK data is encoded using this format.
  /// - Returns: Decoded data
  public func base64URLDecode() -> Data? {
    var str = self
    // add padding if necessary
    str = str.padding(toLength: ((str.count + 3) / 4) * 4, withPad: "=", startingAt: 0)
    // URL decode
    str = str.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
    let d = Data(base64Encoded: str)
    return d
  }
}
