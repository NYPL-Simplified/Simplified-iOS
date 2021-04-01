//
//  RSAManager.swift
//  SimplyE
//
//  Created by Raman Singh on 2021-03-30.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

class RSAManager {
    
    private(set) var publicKeySec, privateKeySec: SecKey
    private(set) var publicKey, privateKey: String
    
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
        kSecAttrApplicationTag:"com.xeoscript.app.RsaFromScrach.private".data(using: String.Encoding.utf8)! as NSObject,
        kSecClass: kSecClassKey, // added this value
        kSecReturnData: kCFBooleanTrue]
    
    private static let publicKeyAttr: [NSObject: NSObject] = [
        kSecAttrIsPermanent:true as NSObject,
        kSecAttrApplicationTag:"com.xeoscript.app.RsaFromScrach.public".data(using: String.Encoding.utf8)! as NSObject,
        kSecClass: kSecClassKey, // added this value
        kSecReturnData: kCFBooleanTrue] // added this value
    
    init?() {
        var pubKeySec, privKeySec: SecKey?
        SecKeyGeneratePair(RSAManager.pub_attributes, &pubKeySec, &privKeySec)
        
        guard pubKeySec != nil, privKeySec != nil else {
            return nil
        }
        
        self.publicKeySec = pubKeySec!
        self.privateKeySec = privKeySec!
        
        var resultPublicKey: AnyObject?
        var resultPrivateKey: AnyObject?
        let statusPublicKey = SecItemCopyMatching(RSAManager.publicKeyAttr as CFDictionary, &resultPublicKey)
        let statusPrivateKey = SecItemCopyMatching(RSAManager.privateKeyAttr as CFDictionary, &resultPrivateKey)
        
        guard statusPublicKey == noErr,
            let publicKey = resultPublicKey as? Data,
            statusPrivateKey == noErr,
            let privateKey = resultPrivateKey as? Data
        else {
            return nil
        }
        
        self.publicKey = publicKey.base64EncodedString()
        self.privateKey = privateKey.base64EncodedString()
    }
    
    func encryptText(_ message: String) -> String? {
        guard let messageData = message.data(using: String.Encoding.utf8) else {
            print("Bad message to encrypt")
            return nil
        }
        
        guard let encryptData = SecKeyCreateEncryptedData(publicKeySec,
                                                          .rsaEncryptionOAEPSHA1,
                                                          messageData as CFData,
                                                          nil) else {
                print("Encryption Error")
                return nil
        }
        
        return (encryptData as Data).base64EncodedString()
    }
    
    func decryptText(_ encryptedString: String) -> String? {
        guard let messageData = Data(base64Encoded: encryptedString, options: []) else {
            print("Bad message to decrypt")
            return nil
        }
        
        guard let decryptData = SecKeyCreateDecryptedData(
            privateKeySec,
            .rsaEncryptionOAEPSHA1,
            messageData as CFData,
            nil) else {
                print("Decryption Error")
                return nil
        }
        
        let decryptedData = decryptData as Data
        
        guard let decryptedString = String(data: decryptedData,
                                           encoding: String.Encoding.utf8)
            else {
                print("Error retrieving string")
                return nil
        }
        
        return decryptedString
    }
    
    func getPublicKey() -> String {
        return self.publicKey
    }
    
    func getPrivateKey() -> String? {
        return self.privateKey
    }
}
