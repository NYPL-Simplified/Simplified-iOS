//
//  AxisLicenseURLGenerator.swift
//  Simplified
//
//  Created by Raman Singh on 2021-04-06.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

import Foundation

/// Generates license URL for a given book with Axis DRM using the bookVaultId, isbn, clientId, deviceId, and
/// a NYPLRSACryptographing object.
///
/// Note: The isbn and bookVauldId are received from the very first file that gets downloaded when we
/// download a book with Axis DRM.
///
/// For generating license for a book with AxisDRM, we need `bookVaultId`, `isbn`, `deviceID`,
/// `IP address`of the client, `modulus` of public key, and `exponent` from rsa client. The url should
/// look this - baseURL/bookVaultId/deviceID/ipAddress/isbn/modulus/exponent
struct AxisLicenseURLGenerator {
  let baseURL: URL
  let bookVaultId: String
  let clientIP: String
  let cypher: NYPLRSACryptographing
  let deviceID: String
  let isbn: String
  
  func generateLicenseURL() -> URL {
    let modulus = cypher.modulus
    let exponent = cypher.exponent
    
    let licenseURL = baseURL
      .appendingPathComponent(bookVaultId)
      .appendingPathComponent(deviceID)
      .appendingPathComponent(clientIP)
      .appendingPathComponent(isbn)
      .appendingPathComponent(modulus)
      .appendingPathComponent(exponent)
    
    return licenseURL
  }
  
}
