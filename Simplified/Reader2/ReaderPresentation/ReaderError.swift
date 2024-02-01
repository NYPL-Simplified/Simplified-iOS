//
//  ReaderError.swift
//  Simplified
//
//  Created by Mickaël Menu on 12.06.19.
//
//  Copyright 2019 European Digital Reading Lab. All rights reserved.
//  Licensed to the Readium Foundation under one or more contributor license agreements.
//  Use of this source code is governed by a BSD-style license which is detailed in the
//  LICENSE file present in the project repository where this source code is maintained.
//

import Foundation

enum ReaderError: LocalizedError {
  case formatNotSupported
  case epubNotValid(String)

  var errorDescription: String? {
    switch self {
    case .formatNotSupported:
      return NSLocalizedString("The book you were trying to read is in an unsupported format.", comment: "Error message when trying to read a publication with a unsupported format")
    case .epubNotValid(let errorCause):
      return String.localizedStringWithFormat(
        NSLocalizedString("The book you were trying to read is corrupted (%@). Please try downloading it again.", comment: "Error message when trying to read an EPUB that is invalid"),
        errorCause)
    }
  }
}
