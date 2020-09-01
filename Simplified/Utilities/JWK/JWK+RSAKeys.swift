//
//  JWK+RSAKeys.swift
//  SimplyE
//
//  Created by Vladimir Fedorov on 31.08.2020.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

extension JWK {
  /// Private key data
  var privateRSAKey: Data? {
    // Check this is an RSA key
    if kty != "RSA" {
      return nil
    }
    // Decode all JWK RSA-related components
    guard let n = n?.base64URLDecode(),
      let e = e?.base64URLDecode(),
      let d = d?.base64URLDecode(),
      let p = p?.base64URLDecode(),
      let q = q?.base64URLDecode(),
      let dp = dp?.base64URLDecode(),
      let dq = dq?.base64URLDecode(),
      let qi = qi?.base64URLDecode()
      else { return nil }
    // Make RSA components
    // https://tools.ietf.org/html/rfc8017#page-55
    // Version 0 = v1
    let version = ASN1.Integer(data: Data([0]))
    let modulus = ASN1.Integer(data: n)
    let publicExponent = ASN1.Integer(data: e)
    let privateExponent = ASN1.Integer(data: d)
    let prime1 = ASN1.Integer(data: p)
    let prime2 = ASN1.Integer(data: q)
    let exponent1 = ASN1.Integer(data: dp)
    let exponent2 = ASN1.Integer(data: dq)
    let coefficient = ASN1.Integer(data: qi)
    // Create ASN.1 sequence with RSA components
    let privateSequence = ASN1.Sequence()
      .appending(version)
      .appending(modulus)
      .appending(publicExponent)
      .appending(privateExponent)
      .appending(prime1)
      .appending(prime2)
      .appending(exponent1)
      .appending(exponent2)
      .appending(coefficient)
    // Return sequence data
    return privateSequence.encodedValue
  }
}
