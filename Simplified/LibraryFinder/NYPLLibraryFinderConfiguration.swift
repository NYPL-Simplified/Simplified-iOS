//
//  NYPLLibraryFinderConfiguration.swift
//  Simplified
//
//  Created by Ernest Fan on 2021-04-28.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

class NYPLLibraryFinderConfiguration {
  static let animationDuration: Double = 0.3
  
  static let collectionViewContentInset: CGFloat = 12.0
  
  static let borderWidth: CGFloat = 1.0
  
  static var borderColor: UIColor {
    if #available(iOS 13.0, *) {
      return UIColor.systemGray4
    } else {
      return UIColor.init(white: 230.0/255.0, alpha: 1.0)
    }
  }
  
  static var cellBackgroundColor: UIColor {
    if #available(iOS 13.0, *) {
      return .systemBackground
    }
    return .white
  }
  
  static func cellCornerRadius(type: NYPLLibraryFinderLibraryCellType) -> CGFloat {
    switch type {
    case .myLibrary:
      return 0.0
    case .newLibrary:
      return 8.0
    }
  }
}
