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
  var isbnKey: String { get }
  var bookVaultKey: String { get }
  var baseURL: URL { get }
  var licenseBaseURL: URL { get }
  var desiredNameForLicenseFile: String { get }
  var containerDownloadEndpoint: String { get }
  var containerFileName: String { get }
  var encryptionDownloadEndpoint: String { get }
  var hrefKey: String { get }
  var fullPathKey: String { get }
}

struct NYPLAxisKeysProvider: NYPLAxisKeysProviding {
  let isbnKey = "isbn"
  let bookVaultKey = "book_vault_uuid"
  /// This is the url for downloading content for a given book with axis drm.
  let baseURL = URL(string: "https://node.axisnow.com/content/stream/")!
  /// Default base URL for downloading license for a book from Axis
  let licenseBaseURL = URL(string: "https://node.axisnow.com/license")!
  let desiredNameForLicenseFile = "license.json"
  let containerDownloadEndpoint = "META-INF/container.xml"
  let containerFileName = "container.xml"
  let encryptionDownloadEndpoint = "META-INF/encryption.xml"
  let hrefKey = "href"
  let fullPathKey = "full-path"
}

#endif
