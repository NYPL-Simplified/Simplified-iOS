//
//  NYPLRSACypher.swift
//  Simplified
//
//  Created by Raman Singh on 2021-04-01.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

protocol NYPLRSACryptographing {
  var publicKeySec: SecKey { get }
  var privateKeySec: SecKey { get }
  var publicKey: String { get }
  var privateKey: String { get }
  func encryptText(_ message: String) -> String?
  func decryptText(_ encryptedString: String) -> String?
}

class NYPLRSACypher: NYPLRSACryptographing {
  
  let publicKeySec, privateKeySec: SecKey
  let publicKey, privateKey: String
  
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
  }
  
  func encryptText(_ message: String) -> String? {
    guard let messageData = message.data(using: String.Encoding.utf8) else {
      return nil
    }
    
    let encryptData = SecKeyCreateEncryptedData(publicKeySec,
                                         .rsaEncryptionOAEPSHA1,
                                         messageData as CFData,
                                         nil)
    
    if let encryptData = encryptData {
      return (encryptData as Data).base64EncodedString()
    }
    
    return nil
  }
  
  func decryptText(_ encryptedString: String) -> String? {
    guard let messageData = Data(base64Encoded: encryptedString, options: []) else {
      return nil
    }
    
    let decryptData = SecKeyCreateDecryptedData(privateKeySec,
                                            .rsaEncryptionOAEPSHA1,
                                            messageData as CFData,
                                            nil)
    
    if let decryptData = decryptData {
      return String(data: decryptData as Data, encoding: String.Encoding.utf8)
    }
    
    return nil
  }
  
}
