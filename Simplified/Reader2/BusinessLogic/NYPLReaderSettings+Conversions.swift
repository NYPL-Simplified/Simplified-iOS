//
//  NYPLReaderSettings+Conversions.swift
//  Simplified
//
//  Created by Ettore Pasquini on 7/14/21.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

extension NYPLReaderSettingsFontFace {
  static func fromRawValue(_ rawValue: NSInteger) -> NYPLReaderSettingsFontFace {
    switch rawValue {
    case 0:
      return .sans
    case 1:
      return .serif
    case 2:
      return .openDyslexic
    default:
      return .sans
    }
  }
}
