//
//  NYPLRSACypher.swift
//  Simplified
//
//  Created by Raman Singh on 2021-04-06.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

protocol NYPLRSACryptographing {
  var publicKey: String { get }
  var privateKey: String { get }
  var modulus: String { get }
  var exponent: String { get }
  func encryptText(_ message: String) -> String?
  func decryptText(_ encryptedString: String) -> String?
}

struct NYPLRSACypher: NYPLRSACryptographing {
  
  let exponent: String
  let modulus: String
  let privateKey: String
  let publicKey: String
  private let privateKeySec: SecKey
  private let publicKeySec: SecKey
  
  private static var pub_attributes: CFDictionary = {
    var keyPairAttr = [NSObject: NSObject]()
    keyPairAttr[kSecAttrKeyType] = kSecAttrKeyTypeRSA
    keyPairAttr[kSecAttrKeySizeInBits] = 2048 as NSObject
    keyPairAttr[kSecPublicKeyAttrs] = publicKeyAttr as NSObject
    keyPairAttr[kSecPrivateKeyAttrs] = privateKeyAttr as NSObject
    return keyPairAttr as CFDictionary
  }()
  
  private static let privateKeyAttr: [NSObject: NSObject] = [
    kSecAttrIsPermanent:true as NSObject,
    kSecAttrApplicationTag:"nypl.rsa.private".data(using: String.Encoding.utf8)! as NSObject,
    kSecClass: kSecClassKey,
    kSecReturnData: kCFBooleanTrue]
  
  private static let publicKeyAttr: [NSObject: NSObject] = [
    kSecAttrIsPermanent:true as NSObject,
    kSecAttrApplicationTag:"nypl.rsa.public".data(using: String.Encoding.utf8)! as NSObject,
    kSecClass: kSecClassKey,
    kSecReturnData: kCFBooleanTrue]
  
  init?() {
    var pubKeySec, privKeySec: SecKey?
    SecKeyGeneratePair(NYPLRSACypher.pub_attributes, &pubKeySec, &privKeySec)
    
    guard let pubSec = pubKeySec, let privSec = privKeySec else {
      return nil
    }
    
    self.publicKeySec = pubSec
    self.privateKeySec = privSec
    
    var resultPublicKey: AnyObject?
    var resultPrivateKey: AnyObject?
    
    let statusPublicKey = SecItemCopyMatching(
      NYPLRSACypher.publicKeyAttr as CFDictionary,
      &resultPublicKey)
    
    let statusPrivateKey = SecItemCopyMatching(
      NYPLRSACypher.privateKeyAttr as CFDictionary,
      &resultPrivateKey)
    
    guard
      let publicKey = resultPublicKey as? Data,
      let privateKey = resultPrivateKey as? Data,
      statusPrivateKey == noErr,
      statusPublicKey == noErr
      else {
        return nil
    }
    
    self.publicKey = publicKey.base64EncodedString()
    self.privateKey = privateKey.base64EncodedString()
    self.modulus = self.publicKey.replacingOccurrences(of: "/", with: "-")
    // we're creating a key with 2048 bits. Exponent for that is AQAB.
    self.exponent = "AQAB"
  }
  
  func encryptText(_ message: String) -> String? {
    guard
      let messageData = message.data(using: .utf8),
      let encryptedData = SecKeyCreateEncryptedData(publicKeySec,
                                                    .rsaEncryptionOAEPSHA1,
                                                    messageData as CFData,
                                                    nil)
      else {
        return nil
    }
    
    return (encryptedData as Data).base64EncodedString()
  }
  
  func decryptText(_ encryptedString: String) -> String? {
    guard
      let messageData = Data(base64Encoded: encryptedString),
      let decryptData = SecKeyCreateDecryptedData(privateKeySec,
                                              .rsaEncryptionOAEPSHA1,
                                              messageData as CFData,
                                              nil)
      else {
        return nil
    }

    return String(data: decryptData as Data, encoding: String.Encoding.utf8)
  }
  
}
