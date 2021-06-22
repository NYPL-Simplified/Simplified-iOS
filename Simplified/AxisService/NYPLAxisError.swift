//
//  NYPLAxisError.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-06-24.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

enum NYPLAxisError: Error {
  /// license.json does not contain the required keys for validating
  case corruptLicense
  /// container file does not contain the path to package file
  case invalidContainerFile
  /// license file does not match the book_vault_id we sent while requesting license
  case invalidLicense
  /// package file does not contain the required package endpoint
  case invalidPackageFile
  /// A dependency deallocated prematurely
  case prematureDeallocation
  /// user cancelled download by pressing the cancel button
  case userCancelledDownload
  /// other error (either failed download or failure to write asset)
  case other(Error)
}
