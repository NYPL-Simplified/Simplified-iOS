//
//  NSError+NYPLAdditions.swift
//  Simplified
//
//  Created by Ettore Pasquini on 5/22/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

extension NSError {

  /// The localized description and recovery suggestion, if present, separated
  /// by a newline.
  @objc var localizedDescriptionWithRecovery: String {
    guard let suggestion = localizedRecoverySuggestion else {
      return localizedDescription
    }

    guard !suggestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      return localizedDescription
    }

    return localizedDescription + "\n\n" + suggestion
  }
}
