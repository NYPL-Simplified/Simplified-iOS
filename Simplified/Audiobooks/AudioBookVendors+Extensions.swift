//
//  AudioBookVendors+Extensions.swift
//  SimplyE
//
//  Created by Vladimir Fedorov on 03.09.2020.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

#if FEATURE_AUDIOBOOKS

import Foundation
import NYPLAudiobookToolkit

extension AudioBookVendors {
  
  /// Vendor tag
  private var tag: String {
    "\(FeedbookDRMPublicKeyTag)\(self.rawValue)"
  }
  
  /// UserDefaults key to store certificate date
  private var validThroughDateKey: String {
    "\(tag)_validThroughDate"
  }
  
  /// Update vendor's DRM key
  /// - Parameter completion: Completion
  func updateDrmCertificate(completion: ((_ error: Error?) -> ())? = nil) {
    switch self {
    case .cantook: updateCantookDRMCertificate(completion: completion)
    }
  }
  
  /// Update Cantook DRM public key
  ///
  /// If the key is saved and its saved expiration date is later than today, the function doesn't request a new public key.
  /// - Parameter completion: Completion
  private func updateCantookDRMCertificate(completion: ((_ error: Error?) -> ())? = nil) {
    // Check if we have a valid key
    if let date = UserDefaults.standard.value(forKey: validThroughDateKey) as? Date, Date() < date {
      // we have a certificate with a valid date
      completion?(nil)
      return
    }
    
    // Fetch a new drmKey
    DPLAAudiobooks.drmKey { (data, date, error) in
      if let error = error {
        if error is DPLAAudiobooks.DPLAError {
          Log.error(#file, "DPLA key-fetch error: \(error)")
        } else {
          Log.error(#file, "Could not receive DRM public key, URL: \(DPLAAudiobooks.certificateUrl): \(error)")
        }
        completion?(error)
        return
      }
      // drmKey completion handler returns either non-empty data value or an error
      guard let keyData = data else {
        Log.error(#file, "Public key data is empty, URL: \(DPLAAudiobooks.certificateUrl)")
        completion?(DPLAAudiobooks.DPLAError.drmKeyError("Public key data is empty, URL: \(DPLAAudiobooks.certificateUrl)"))
        return
      }
      // Check if we have a valid date
      if let date = date {
        // Save this date to avoid fetching this certificate untill it becomes invalid
        UserDefaults.standard.set(date, forKey: self.validThroughDateKey)
      }
      
      // Save SecKey
      let addQuery: [String: Any] = [
        kSecClass as String: kSecClassKey,
        kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
        kSecAttrApplicationTag as String: self.tag.data(using: .utf8) as Any,
        kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        kSecValueData as String: keyData,
        kSecAttrKeyClass as String: kSecAttrKeyClassPublic
      ]

      // Clean up before adding a new key value
      SecItemDelete(addQuery as CFDictionary)
      let status = SecItemAdd(addQuery as CFDictionary, nil)
      if status != errSecSuccess && status != errSecDuplicateItem {
        NYPLKeychainManager.logKeychainError(forVendor: self.rawValue, status: status, message: "FeedbookDrmPrivateKeyManagement Error:")
      }
      
      completion?(nil)
    }
  }
}

#endif//FEATURE_AUDIOBOOKS
