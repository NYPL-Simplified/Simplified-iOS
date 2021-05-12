//
//  NYPLAxisKeysProvider.swift
//  Simplified
//
//  Created by Raman Singh on 2021-04-22.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

#if AXIS

protocol NYPLAxisKeysProviding {
  var baseURL: URL { get }
  var bookFilePathKey: String { get }
  var bookVaultKey: String { get }
  var containerDownloadEndpoint: String { get }
  var containerFileName: String { get }
  var decryptedAESKeyPath: String { get }
  var desiredNameForLicenseFile: String { get }
  var encryptionDownloadEndpoint: String { get }
  var fullPathKey: String { get }
  var hrefKey: String { get }
  var isbnKey: String { get }
  var licenseBaseURL: URL { get }
}

struct NYPLAxisKeysProvider: NYPLAxisKeysProviding {
  /// This is the url for downloading content for a given book with axis drm.
  let baseURL = URL(string: "https://node.axisnow.com/content/stream/")!
  let bookFilePathKey = "bookFile.axis"
  let bookVaultKey = "book_vault_uuid"
  let containerDownloadEndpoint = "META-INF/container.xml"
  let containerFileName = "container.xml"
  let decryptedAESKeyPath = "aesKey"
  let desiredNameForLicenseFile = "license.json"
  let encryptionDownloadEndpoint = "META-INF/encryption.xml"
  let fullPathKey = "full-path"
  let hrefKey = "href"
  let isbnKey = "isbn"
  /// Default base URL for downloading license for a book from Axis
  let licenseBaseURL = URL(string: "https://node.axisnow.com/license")!
}

#endif
