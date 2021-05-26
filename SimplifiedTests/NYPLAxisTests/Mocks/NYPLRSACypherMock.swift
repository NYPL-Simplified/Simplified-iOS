//
//  NYPLRSACypherMock.swift
//  OpenEbooksTests
//
//  Created by Raman Singh on 2021-05-20.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//
import Foundation
@testable import SimplyE

struct NYPLRSACypherMock: NYPLRSACryptographing {

  let publicKey: String
  let privateKey: String
  let modulus: String
  let exponent: String
  var rsaClosure: (() -> String)?
  var aesClosure: (() -> Data?)?

  init(publicKey: String = "", privateKey: String = "", modulus: String = "",
       exponent: String = "", rsaClosure: (() -> String)?,
       aesClosure: (() -> Data?)?) {

    self.publicKey = publicKey
    self.privateKey = privateKey
    self.modulus = modulus
    self.exponent = exponent
    self.rsaClosure = rsaClosure
    self.aesClosure = aesClosure
  }

  func decryptWithPKCS1_OAEP(_ data: Data) -> Data? {
    guard let value = rsaClosure?() else {
      return nil
    }

    return value.data(using: .utf8)
  }

  func decryptWithAES(_ data: Data, key: Data) -> Data? {
    return aesClosure?()
  }
}
