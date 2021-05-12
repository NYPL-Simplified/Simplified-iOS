//
//  NYPLRSACypher.swift
//  Simplified
//
//  Created by Raman Singh on 2021-04-06.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
import CommonCrypto
import CryptoSwift

#if AXIS

protocol NYPLRSACryptographing {
  var publicKey: String { get }
  var privateKey: String { get }
  var modulus: String { get }
  var exponent: String { get }
  func decryptWithPKCS1_OAEP(_ data: Data) -> Data?
  func decryptWithAES(_ data: Data, key: Data) -> Data?
}

struct NYPLRSACypher: NYPLRSACryptographing {
  
  let exponent: String
  let modulus: String
  let privateKey: String
  let publicKey: String
  let privateKeySec: SecKey
  let publicKeySec: SecKey
  
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
    
    guard
      let (mod, exp) = NYPLRSACypher.parsePublicSecKey(publicKey: self.publicKeySec)
    else {
      NYPLRSACypher
        .logFailedInitializationError(
          "Failed to get exponent and or modulus for public key")
        return nil
    }
    
    let modulus = mod.base64EncodedString()
    guard modulus.count >= 342 else {
      NYPLRSACypher
        .logFailedInitializationError("Got incorrect modulus from public key")
      return nil
    }
    
    self.modulus = String(modulus.prefix(342)).replacingOccurrences(of: "/", with: "_")
    self.exponent = exp.base64EncodedString()
  }
  
  static private func parsePublicSecKey(publicKey: SecKey) -> (mod: Data, exp: Data)? {
    
    guard let pubAttributes = SecKeyCopyAttributes(publicKey) as? [String: Any] else {
      return nil
    }
    
    let keySize = pubAttributes[kSecAttrKeySizeInBits as String] as! Int
    let pubData  = pubAttributes[kSecValueData as String] as! Data
    var modulus  = pubData.subdata(in: 8..<(pubData.count - 5))
    let exponent = pubData.subdata(in: (pubData.count - 3)..<pubData.count)
    
    if modulus.count > keySize / 8 { // --> 257 bytes
      modulus.removeFirst(1)
    }
    
    return (mod: modulus, exp: exponent)
  }
  
  func decryptWithPKCS1_OAEP(_ data: Data) -> Data? {
    guard let decryptData = SecKeyCreateDecryptedData(privateKeySec,
                                                      .rsaEncryptionOAEPSHA1,
                                                      data as CFData,
                                                      nil)
      else {
        NYPLRSACypher
          .logFailedDecryptionError(NYPLRSACypher.nilDecryptedDataFailure)
        return nil
    }
    return decryptData as Data
  }
  
  func decryptWithAES(_ data: Data, key: Data) -> Data? {
    let content = data.subdata(in: 4..<data.count)
    let keyLength = key.count
    let validKeyLengths = [kCCKeySizeAES128, kCCKeySizeAES192, kCCKeySizeAES256]
    if (validKeyLengths.contains(keyLength) == false) {
        return nil
    }

    let ivSize = kCCBlockSizeAES128;
    let clearLength = size_t(content.count - ivSize)
    var clearData = Data(count:clearLength)

    var numBytesDecrypted :size_t = 0
    let options   = CCOptions(kCCOptionPKCS7Padding)

    let cryptStatus = clearData.withUnsafeMutableBytes {cryptBytes in
        content.withUnsafeBytes {dataBytes in
            key.withUnsafeBytes {keyBytes in
                CCCrypt(CCOperation(kCCDecrypt),
                        CCAlgorithm(kCCAlgorithmAES128),
                        options,
                        keyBytes, keyLength,
                        dataBytes,
                        dataBytes+kCCBlockSizeAES128, clearLength,
                        cryptBytes, clearLength,
                        &numBytesDecrypted)
            }
        }
    }

    if UInt32(cryptStatus) == UInt32(kCCSuccess) {
        clearData.count = numBytesDecrypted
    } else {
        return nil
    }
    
    return clearData
  }
  
  static private func logFailedInitializationError(_ reason: String) {
    NYPLErrorLogger.logError(
      withCode: .axisCriptographyFail,
      summary: NYPLRSACypher.failedInitializationSummary,
      metadata: [NYPLAxisService.reason: reason])
  }
  
  static private func logFailedDecryptionError(_ reason: String) {
    NYPLErrorLogger.logError(
      withCode: .axisCriptographyFail,
      summary: NYPLRSACypher.failedDecryptionSummary,
      metadata: [NYPLAxisService.reason: reason])
  }
  
}

#endif
