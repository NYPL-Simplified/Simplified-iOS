//
//  NYPLAxisLicenseService.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-05-11.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

protocol NYPLAxisLicenseHandling {
  func deleteLicenseFile()
  func downloadLicense()
  func saveBookInfoFromLicense()
  func validateLicense()
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
  
  static private let licenseValidationFailureSummary = "Axis failed to validate license"
  
  let axisItemDownloader: NYPLAxisItemDownloading
  let axisKeysProvider: NYPLAxisKeysProviding
  let bookVaultId: String
  let cypher: NYPLRSACryptographing
  let deviceInfoProvider: NYPLDeviceInfoProviding
  let isbn: String
  let parentDirectory: URL
  let localLicenseURL: URL
  
  init(axisItemDownloader: NYPLAxisItemDownloading,
       axisKeysProvider: NYPLAxisKeysProviding = NYPLAxisKeysProvider(),
       bookVaultId: String,
       cypher: NYPLRSACryptographing,
       deviceInfoProvider: NYPLDeviceInfoProviding = NYPLAxisDRMAuthorizer.sharedInstance,
       isbn: String,
       parentDirectory: URL) {
    
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
  
  func downloadLicense() {
    axisItemDownloader.dispatchGroup.enter()
    
    let licenseURL = NYPLAxisLicenseURLGenerator(
      baseURL: axisKeysProvider.licenseBaseURL,
      bookVaultId: bookVaultId,
      clientIP: deviceInfoProvider.clientIP,
      cypher: cypher,
      deviceID: deviceInfoProvider.deviceID,
      isbn: isbn
    ).generateLicenseURL()
    
    let writeURL = parentDirectory
      .appendingPathComponent(axisKeysProvider.desiredNameForLicenseFile)
    axisItemDownloader.downloadItem(from: licenseURL, at: writeURL)
  }
  
  /// Validates license by decrypting the value contained in `[encryption][user_key][key_check]`
  /// using our private key and compares it against the bookVaultId we sent while requesting the license.
  ///
  /// - Note: We delete the license file upon validation in order to adhere to Axis guidelines. We do
  /// however store the book_vault_id and isbn for downloading license again when the user wants to open
  /// the book for reading.
  func validateLicense() {
    axisItemDownloader.dispatchGroup.wait()
    axisItemDownloader.dispatchGroup.enter()
    guard
      let data = try? Data(contentsOf: localLicenseURL),
      let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed),
      let json = jsonObject as? [String: Any],
      let encryptionNode = json["encryption"] as? [String: Any],
      let userKey = encryptionNode["user_key"] as? [String: Any],
      let encryptedBookVaultId = userKey["key_check"] as? String,
      let base64Data = Data(base64Encoded: encryptedBookVaultId),
      let decryptedBookVaultData = cypher.decryptWithPKCS1_OAEP(base64Data),
      let decryptedBookVaultId = String(data: decryptedBookVaultData, encoding: .utf8)
    else {
      logLicenseError()
      axisItemDownloader.leaveGroupAndStopDownload()
      return
    }
    
    let isValid = decryptedBookVaultId == bookVaultId
    guard isValid else {
      logLicenseError()
      axisItemDownloader.leaveGroupAndStopDownload()
      return
    }
    
    axisItemDownloader.dispatchGroup.leave()
  }
  
  /// Writes book isbn and book_vault_id to be used for fetching license before opening book for reading
  func saveBookInfoFromLicense() {
    axisItemDownloader.dispatchGroup.wait()
    axisItemDownloader.dispatchGroup.enter()
    let designatedBookInfoURL = parentDirectory
      .appendingPathComponent(axisKeysProvider.bookFilePathKey)
    
    let bookInfo: NSDictionary = [axisKeysProvider.isbnKey: isbn,
                                  axisKeysProvider.bookVaultKey: bookVaultId]
    
    let success: Bool
    do {
      let data = try JSONSerialization.data(withJSONObject: bookInfo,
                                            options: .prettyPrinted)
      
      success = FileManager.default.createFile(
        atPath: designatedBookInfoURL.path, contents: data, attributes: nil)
    } catch {
      logLicenseError(reason: error.localizedDescription)
      axisItemDownloader.leaveGroupAndStopDownload()
      return
    }
    
    guard success else {
      logLicenseError(reason: "Axis failed to move book file to designated url")
      axisItemDownloader.leaveGroupAndStopDownload()
      return
    }
    
    axisItemDownloader.dispatchGroup.leave()
  }
  
  /// Delete license file to adhere with Axis DRM guidelines
  func deleteLicenseFile() {
    axisItemDownloader.dispatchGroup.wait()
    axisItemDownloader.dispatchGroup.enter()
    
    do {
      try FileManager.default.removeItem(at: localLicenseURL)
    } catch {
      logLicenseError(reason: error.localizedDescription)
      axisItemDownloader.leaveGroupAndStopDownload()
      return
    }
    
    axisItemDownloader.dispatchGroup.leave()
  }
  
  func encryptedContentKeyData() -> Data? {
    axisItemDownloader.dispatchGroup.wait()
    axisItemDownloader.dispatchGroup.enter()
    
    guard
      let data = try? Data(contentsOf: localLicenseURL),
      let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed),
      let json = jsonObject as? [String: Any],
      let encryptionNode = json["encryption"] as? [String: Any],
      let encryptedContent = encryptionNode["content_key"] as? [String: Any],
      let encryptedContentValue = encryptedContent["encrypted_value"] as? String
    else {
      logLicenseError(reason: "Axis failed to get encrypted aes key")
      axisItemDownloader.leaveGroupAndStopDownload()
      return nil
    }
    
    defer {
      axisItemDownloader.dispatchGroup.leave()
    }
    
    return Data(base64Encoded: encryptedContentValue)
  }
  
  private func logLicenseError(reason: String = "Axis failed to validate license") {
    NYPLErrorLogger.logError(
      withCode: .axisDRMFulfillmentFail,
      summary: NYPLAxisLicenseService.licenseValidationFailureSummary,
      metadata: [NYPLAxisService.reason: reason])
  }
  
}
