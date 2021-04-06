//
//  AxisLicenseURLGenerator.swift
//  Simplified
//
//  Created by Raman Singh on 2021-04-06.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

struct AxisLicenseURLGenerator {
  let isbn: String
  let bookVaultId: String
  
  var licenseURL: URL? {
    guard let rsa = NYPLRSACypher() else {
      return nil
    }
    
    let modulus = rsa.publicKey.replacingOccurrences(of: "/", with: "-")
    let exponent = "AQAB"
    let baseURL = URL(string: "https://node.axisnow.com/license")!
    // TODO: Fix this
    let deviceId: String = UUID().uuidString
    let clientIp = "192.168.0.1"
    let licenseURL = baseURL
      .appendingPathComponent(bookVaultId)
      .appendingPathComponent(deviceId)
      .appendingPathComponent(clientIp)
      .appendingPathComponent(isbn)
      .appendingPathComponent(modulus)
      .appendingPathComponent(exponent)
    
    return licenseURL
  }
  
}
