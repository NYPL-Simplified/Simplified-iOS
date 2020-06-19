//
//  StdLib+NYPLAdditions.swift
//  Simplified
//
//  Created by Ettore Pasquini on 6/17/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

infix operator =~= : ComparisonPrecedence

extension Float {

  /// Performs equality check minus an epsilon
  /// - Returns: `true` if the numbers differ by less than the epsilon,
  /// `false` otherwise.
  static func =~= (a: Float, b: Float?) -> Bool {
    guard let b = b else {
      return false
    }

    return abs(a - b) < Float.ulpOfOne
  }
}

