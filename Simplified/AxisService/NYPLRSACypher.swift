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
    
    /// The minimum length of base64 string generated from mod data should be 342. Anything less and the
    /// license file we get will be unusable since we won't be able to decrypt bookVaultId and AES key in our
    /// license file using our private key.
    let modulus = mod.base64EncodedString()
    guard modulus.count >= 342 else {
      NYPLRSACypher
        .logFailedInitializationError("Got incorrect modulus from public key")
      return nil
    }
    
    self.modulus = String(modulus.prefix(342)).replacingOccurrences(of: "/", with: "_")
    self.exponent = exp.base64EncodedString()
  }
  
  /**
   `This is how this method works:`
   
   We first extract a CFDictionary from the public key, from that key we get the key size and key data. Key data
   content is DER-encoded ASN for
   
   SEQUENCE {
    modulus INTEGER,
    publicExponent INTEGER
   }
   
   These integers are padded with a zero byte if they are positive, and have a leading 1-bit. Therefore we
   might get one extra byte. If that happens, we just cut it away.
   
   Here's what the data looks like
   First 8 bits - some bits we do not need. Anything after that upto the 5th last bit is modulus. And the last 3
   bytes are the exponent.
   
   Our public key is 2048 bits long. Modulus for a public key is 1/8th the key size. But since we might have a
   leading 1-bit, in which case our modulus will be 257 bytes, we remove the extra leading byte.
   
   https://stackoverflow.com/a/43225656/5840458
   */
  static private func parsePublicSecKey(publicKey: SecKey) -> (mod: Data, exp: Data)? {
    
    // Extract key data and size from public key
    guard
      let pubAttributes = SecKeyCopyAttributes(publicKey) as? [String: Any],
      let keySize = pubAttributes[kSecAttrKeySizeInBits as String] as? Int,
      let pubData = pubAttributes[kSecValueData as String] as? Data
    else {
      return nil
    }
    
    var modulus = pubData.subdata(in: 8..<(pubData.count - 5))
    let exponent = pubData.subdata(in: (pubData.count - 3)..<pubData.count)
    
    // Remove leading 1-bit if present
    if modulus.count > keySize / 8 {
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
  
  
  /// Decrypts given data using the aes key provided in data format.
  ///
  /// - Note: Taken from https://stackoverflow.com/a/25755864/5840458
  /// 
  /// - Parameters:
  ///   - data: AES encrypted data
  ///   - key: AES key
  /// - Returns: Decrypted data. Returns nil if decryption is unsuccessful or AES key length is invalid.
  func decryptWithAES(_ data: Data, key: Data) -> Data? {
    // The iv (4 bits) is prefixed to data
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
    
    let cryptStatus = clearData
      .withUnsafeMutableBytes { cryptBytes in
        content.withUnsafeBytes { dataBytes in
          key.withUnsafeBytes { keyBytes in
            CCCrypt(CCOperation(kCCDecrypt), CCAlgorithm(kCCAlgorithmAES128),
                    options, keyBytes, keyLength, dataBytes,
                    dataBytes+kCCBlockSizeAES128, clearLength, cryptBytes,
                    clearLength, &numBytesDecrypted)
          }
        }
      }
    
    if UInt32(cryptStatus) == UInt32(kCCSuccess) {
      clearData.count = numBytesDecrypted
      return clearData
    }
    
    return nil
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
