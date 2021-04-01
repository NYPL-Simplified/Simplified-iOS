//
//  AxisNowLicenseManager.swift
//  Simplified
//
//  Created by Raman Singh on 2021-03-30.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation


@objc
class AxisLicenseExtractor: NSObject {
    
    private let licenseURL: URL
    
    init(licenseURL: URL) {
        self.licenseURL = licenseURL
        super.init()
    }
    
    func extractValuesFromLicense() -> String {
        guard
            let data = try? Data(contentsOf: licenseURL),
            let jsonObject = try? JSONSerialization
                .jsonObject(with: data, options: .fragmentsAllowed),
            let license = jsonObject as? [String: Any]
            else {
                return ""
        }
        
        let contentKeyEncrypted = getEncryptedContentKeyFromLicense(license)
        let keyCheck = getKeyCheckFromLicense(license)
        print(keyCheck)
        
        /*
         key_check_decrypted = self.decryptor.cipher.decrypt(decodebytes(key_check.encode("ascii")))
         */
        
            
        return ""
    }
    
    private func getEncryptedContentKeyFromLicense(_ license: [String: Any]) -> String {
        guard let encryption = license["encryption"] as? [String: Any],
            let contentKey = encryption["content_key"] as? [String: Any],
            let encrypted = contentKey["encrypted_value"] as? String
            else {
                return ""
        }
        
        return encrypted
    }
    
    private func getKeyCheckFromLicense(_ license: [String: Any]) -> String {
        //license['encryption']['user_key']['key_check']
        guard let encryption = license["encryption"] as? [String: Any],
            let userKey = encryption["user_key"] as? [String: Any],
            let keycheck = userKey["key_check"] as? String
            else {
                return ""
        }
        
        return keycheck
    }
    
}

