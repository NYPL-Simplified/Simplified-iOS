//
//  NYPLAxisLicenseService.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-05-11.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

protocol NYPLAxisLicenseHandling {
  func makeDownloadLicenseTask() -> NYPLAxisTask
  func makeValidateLicenseTask() -> NYPLAxisTask
  func makeSaveBookInfoTask() -> NYPLAxisTask
  func makeDeleteLicenseTask() -> NYPLAxisTask
  func encryptedContentKeyData() -> Data?
}

/// Responsible for downloading and validating license.
///
///`Here's how license validation works:`
///
/// We first generate a private key. From that key, we create a public key. For downloading the license, we
/// need the values for `book isbn`, `book vault id`, `client IP address`, `device ID`,
/// and `modulus and exponent from the public key`. The license file we get is supposed to
/// contain the `book_vault_id` encrypted using the public key we provided. If it does, it means the
/// license is valid.
///
struct NYPLAxisLicenseService: NYPLAxisLicenseHandling {
  
  static private let licenseValidationFailureSummary = "AxisLicenseService failed to validate license"
  static private let saveBookInfoFailureSummary = "AxisLicenseService failed to write book info"
  static private let deleteLicenseFileFailureSummmay = "AxisLicenseService failed to delete license file"
  static private let extractAESKeyFailureSummary = "AxisLicenseService failed to extract AES key"
  
  static private let missingKeys = "AxisLicenseService validation failed due to missing keys"
  static private let invalidKeyCheck = "AxisLicenseService validation failed due to invalid keyCheck"
  static private let invalidVaultId = "AxisLicenseService validation failed due to invalid vault ID in license"
  static private let misssingAESKey = "Axis failed to get encrypted aes key"
  
  private let assetWriter: NYPLAssetWriting
  private let axisItemDownloader: NYPLAxisItemDownloading
  private let axisKeysProvider: NYPLAxisKeysProviding
  private let bookVaultId: String
  private let cypher: NYPLRSACryptographing
  private let deviceInfoProvider: NYPLDeviceInfoProviding
  private let isbn: String
  private let parentDirectory: URL
  private let localLicenseURL: URL
  
  init(assetWriter: NYPLAssetWriting = NYPLAssetWriter(),
       axisItemDownloader: NYPLAxisItemDownloading,
       axisKeysProvider: NYPLAxisKeysProviding = NYPLAxisKeysProvider(),
       bookVaultId: String,
       cypher: NYPLRSACryptographing,
       deviceInfoProvider: NYPLDeviceInfoProviding = NYPLAxisDRMAuthorizer.sharedInstance,
       isbn: String,
       parentDirectory: URL) {
    
    self.assetWriter = assetWriter
    self.axisItemDownloader = axisItemDownloader
    self.axisKeysProvider = axisKeysProvider
    self.bookVaultId = bookVaultId
    self.cypher = cypher
    self.deviceInfoProvider = deviceInfoProvider
    self.isbn = isbn
    self.parentDirectory = parentDirectory
    self.localLicenseURL = parentDirectory
      .appendingPathComponent(axisKeysProvider.desiredNameForLicenseFile)
  }
  
  func makeDownloadLicenseTask() -> NYPLAxisTask {
    return NYPLAxisTask { task in
      let licenseURL = NYPLAxisLicenseURLGenerator(
        baseURL: self.axisKeysProvider.licenseBaseURL,
        bookVaultId: self.bookVaultId,
        clientIP: self.deviceInfoProvider.clientIP,
        cypher: self.cypher,
        deviceID: self.deviceInfoProvider.deviceID,
        isbn: self.isbn
      ).generateLicenseURL()
      
      self.axisItemDownloader
        .downloadItem(from: licenseURL, at: self.localLicenseURL) {
          task.processResult($0)
        }
    }
  }
  
  /// Validates license by decrypting the value contained in `[encryption][user_key][key_check]`
  /// using our private key and compares it against the bookVaultId we sent while requesting the license.
  ///
  /// - Note: We delete the license file upon validation in order to adhere to Axis guidelines. We do
  /// however store the book_vault_id and isbn for downloading license again when the user wants to open
  /// the book for reading.
  func makeValidateLicenseTask() -> NYPLAxisTask {
    return NYPLAxisTask { task in
      
      guard
        let data = try? Data(contentsOf: self.localLicenseURL),
        let jsonObject = try? JSONSerialization.jsonObject(
          with: data, options: .fragmentsAllowed),
        let json = jsonObject as? [String: Any],
        let encryptionNode = json[self.axisKeysProvider.encryption] as? [String: Any],
        let userKey = encryptionNode[self.axisKeysProvider.userKey] as? [String: Any],
        let encryptedBookVaultId = userKey[self.axisKeysProvider.keyCheck] as? String
      else {
        self.logFailure(
          summary: NYPLAxisLicenseService.licenseValidationFailureSummary,
          reason: NYPLAxisLicenseService.missingKeys)
        
        task.failed(with: .corruptLicense)
        return
      }
      
      guard
        let base64Data = Data(base64Encoded: encryptedBookVaultId),
        let decryptedBookVaultData = self.cypher.decryptWithPKCS1_OAEP(base64Data),
        let decryptedBookVaultId = String(data: decryptedBookVaultData, encoding: .utf8)
      else {
        self.logFailure(
          summary: NYPLAxisLicenseService.licenseValidationFailureSummary,
          reason: NYPLAxisLicenseService.invalidKeyCheck)
        
        task.failed(with: .invalidLicense)
        return
      }
      
      let isValid = decryptedBookVaultId == self.bookVaultId
      guard isValid else {
        self.logFailure(
          summary: NYPLAxisLicenseService.licenseValidationFailureSummary,
          reason: NYPLAxisLicenseService.invalidVaultId,
          additionalInfo: ["expected": self.bookVaultId,
                           "received": decryptedBookVaultId])
        
        task.failed(with: .invalidLicense)
        return
      }
      
      task.succeeded()
    }
    
  }
  
  /// Writes book isbn and book_vault_id to be used for fetching license before opening book for reading
  func makeSaveBookInfoTask() -> NYPLAxisTask {
    return NYPLAxisTask() { task in
      
      let designatedBookInfoURL = self.parentDirectory
        .appendingPathComponent(self.axisKeysProvider.bookFilePathKey)
      
      let bookInfo: NSDictionary = [self.axisKeysProvider.isbnKey: self.isbn,
                                    self.axisKeysProvider.bookVaultKey: self.bookVaultId]
      
      do {
        let data = try JSONSerialization.data(withJSONObject: bookInfo,
                                              options: .prettyPrinted)
        
        try self.assetWriter.writeAsset(data, atURL: designatedBookInfoURL)
        task.succeeded()
      } catch {
        self.logFailure(
          summary: NYPLAxisLicenseService.saveBookInfoFailureSummary,
          reason: error.localizedDescription)
        task.failed(with: .other(error))
      }
      
    }
  }
  
  /// Delete license file to adhere with Axis DRM guidelines
  func makeDeleteLicenseTask() -> NYPLAxisTask {
    return NYPLAxisTask() { task in
      
      do {
        try FileManager.default.removeItem(at: self.localLicenseURL)
        task.succeeded()
      } catch {
        self.logFailure(
          summary: NYPLAxisLicenseService.deleteLicenseFileFailureSummmay,
          reason: error.localizedDescription)
        task.failed(with: .other(error))
      }
    }
  }
  
  /// Returns encrypted AES key data from extracted base64 string from the license to be used for
  /// decrypting book content
  /// - Returns: Encrypted AES key data. Returns nil if base64 string containing the key not found or
  /// upon failure converting base64 string to data
  func encryptedContentKeyData() -> Data? {
    guard
      let data = try? Data(contentsOf: localLicenseURL),
      let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed),
      let json = jsonObject as? [String: Any],
      let encryptionNode = json[axisKeysProvider.encryption] as? [String: Any],
      let encryptedContent = encryptionNode[axisKeysProvider.contentKey] as? [String: Any],
      let encryptedContentValue = encryptedContent[axisKeysProvider.encryptedValue] as? String
    else {
      logFailure(
        summary: NYPLAxisLicenseService.extractAESKeyFailureSummary,
        reason: NYPLAxisLicenseService.misssingAESKey)
      return nil
    }
    
    return Data(base64Encoded: encryptedContentValue)
  }
  
  private func logFailure(summary: String,
                          reason: String,
                          additionalInfo: [String: String] = [:]) {
    
    var metadata = additionalInfo
    metadata[NYPLAxisService.reason] = reason
    
    NYPLErrorLogger.logError(
      withCode: .axisDRMFulfillmentFail,
      summary: summary,
      metadata: metadata)
  }
  
}
