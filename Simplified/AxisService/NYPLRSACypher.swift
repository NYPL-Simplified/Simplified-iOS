//
//  NYPLRSACypher.swift
//  Simplified
//
//  Created by Raman Singh on 2021-04-06.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

#if AXIS

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
  
  // MARK: - Static Constants
  
  // Key generation constants
  static private let nyplRSAPrivate = "nypl.rsa.private"
  static private let nyplRSAPublic = "nypl.rsa.public"
  
  // Failed Intitialization constants
  static private let failedInitializationSummary = "AXIS: Failed to create NYPLRSACypher object!"
  static private let publicSecKeyGenerationFailure = "Failed to generate public SecKey"
  static private let privateSecKeyGenerationFailure = "Failed to generate private SecKey"
  static private let resultPublicKeyGenerationFailure = "Failed to generate resultPublicKey"
  static private let resultPrivateKeyGenerationFailure = "Failed to generate resultPrivateKey"
  
  // Failed Encryption/Decryption constants
  static private let failedEncryptionSummary = "AXIS: Failed to encrypt text with public key"
  static private let failedDecryptionSummary = "AXIS: Failed to decrypt text with private key"
  static private let stringToDataConversionFailure = "Failed to convert message to data"
  static private let nilEncryptedDataFailure = "encryptedData was nil"
  static private let nilDecryptedDataFailure = "decryptedData was nil"
  
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
    kSecAttrApplicationTag:nyplRSAPrivate.data(using: String.Encoding.utf8)! as NSObject,
    kSecClass: kSecClassKey,
    kSecReturnData: kCFBooleanTrue]
  
  private static let publicKeyAttr: [NSObject: NSObject] = [
    kSecAttrIsPermanent:true as NSObject,
    kSecAttrApplicationTag:nyplRSAPublic.data(using: String.Encoding.utf8)! as NSObject,
    kSecClass: kSecClassKey,
    kSecReturnData: kCFBooleanTrue]
  
  // MARK: - Initialization
  init?() {
    var pubKeySec, privKeySec: SecKey?
    SecKeyGeneratePair(NYPLRSACypher.pub_attributes, &pubKeySec, &privKeySec)
    
    guard let pubSec = pubKeySec else {
      NYPLRSACypher
        .logFailedInitializationError(NYPLRSACypher.publicSecKeyGenerationFailure)
      return nil
    }
    
    guard let privSec = privKeySec else {
      NYPLRSACypher
        .logFailedInitializationError(NYPLRSACypher.privateSecKeyGenerationFailure)
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
    
    guard let publicKey = resultPublicKey as? Data else {
      NYPLRSACypher
        .logFailedInitializationError(NYPLRSACypher.resultPublicKeyGenerationFailure)
      return nil
    }
    
    guard let privateKey = resultPrivateKey as? Data else {
      NYPLRSACypher
        .logFailedInitializationError(NYPLRSACypher.resultPrivateKeyGenerationFailure)
      return nil
    }
    
    guard statusPublicKey == noErr else {
      NYPLRSACypher
        .logFailedInitializationError("statusPublicKey was \(statusPublicKey)")
      return nil
    }
    
    guard statusPrivateKey == noErr else {
      NYPLRSACypher
        .logFailedInitializationError("statusPrivateKey was \(statusPrivateKey)")
      return nil
    }
    
    self.publicKey = publicKey.base64EncodedString()
    self.privateKey = privateKey.base64EncodedString()
    self.modulus = self.publicKey.replacingOccurrences(of: "/", with: "-")
    // we're creating a key with 2048 bits. Exponent for that is AQAB.
    self.exponent = "AQAB"
  }
  
  func encryptText(_ message: String) -> String? {
    let _messageData = message.data(using: .utf8)
    
    guard let messageData = _messageData else {
      NYPLRSACypher
        .logFailedEncryptionError(NYPLRSACypher.stringToDataConversionFailure)
      return nil
    }
    guard let encryptedData = SecKeyCreateEncryptedData(publicKeySec,
                                                        .rsaEncryptionOAEPSHA1,
                                                        messageData as CFData,
                                                        nil)
      else {
        NYPLRSACypher
          .logFailedEncryptionError(NYPLRSACypher.nilEncryptedDataFailure)
        return nil
    }
    
    return (encryptedData as Data).base64EncodedString()
  }
  
  func decryptText(_ encryptedString: String) -> String? {
    let _messageData = Data(base64Encoded: encryptedString)
    
    guard let messageData = _messageData else {
      NYPLRSACypher
        .logFailedDecryptionError(NYPLRSACypher.stringToDataConversionFailure)
      return nil
    }
    
    guard let decryptData = SecKeyCreateDecryptedData(privateKeySec,
                                                      .rsaEncryptionOAEPSHA1,
                                                      messageData as CFData,
                                                      nil)
      else {
        NYPLRSACypher
          .logFailedDecryptionError(NYPLRSACypher.nilDecryptedDataFailure)
        return nil
    }
    
    return String(data: decryptData as Data, encoding: String.Encoding.utf8)
  }
  
  static private func logFailedInitializationError(_ reason: String) {
    NYPLErrorLogger.logError(
      withCode: .axisCriptographyFail,
      summary: NYPLRSACypher.failedInitializationSummary,
      metadata: [NYPLAxisService.reason: reason])
  }
  
  static private func logFailedEncryptionError(_ resson: String) {
    NYPLErrorLogger.logError(
      withCode: .axisCriptographyFail,
      summary: NYPLRSACypher.failedEncryptionSummary,
      metadata: [NYPLAxisService.reason: resson])
  }
  
  static private func logFailedDecryptionError(_ reason: String) {
    NYPLErrorLogger.logError(
      withCode: .axisCriptographyFail,
      summary: NYPLRSACypher.failedDecryptionSummary,
      metadata: [NYPLAxisService.reason: reason])
  }
  
}

#endif
