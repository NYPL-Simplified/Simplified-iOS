//
//  NYPLConfiguration+Color.swift
//  Simplified
//
//  Created by Ernest Fan on 2021-09-16.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

private enum ColorAsset: String {
  case defaultBackground
  case defaultText
  case downloadBackground
  case action
  case deleteAction
  case fieldBackground
  case fieldBorder
  case fieldText
  case progressBarBackground
}

@objc extension NYPLConfiguration {
  static var defaultBackgroundColor: UIColor {
    if #available(iOS 11.0, *),
       let color = UIColor(named: ColorAsset.defaultBackground.rawValue) {
      return color
    }

    return .white
  }
  
  static var defaultTextColor: UIColor {
    if #available(iOS 11.0, *),
       let color = UIColor(named: ColorAsset.defaultText.rawValue) {
      return color
    }

    return .black
  }

  static var downloadBackgroundColor: UIColor {
    if #available(iOS 11.0, *),
       let color = UIColor(named: ColorAsset.downloadBackground.rawValue) {
      return color
    }

    return .lightGray
  }
  
  static var actionColor: UIColor {
    if #available(iOS 11.0, *),
       let color = UIColor(named: ColorAsset.action.rawValue) {
      return color
    }

    return .systemBlue
  }
  
  static var deleteActionColor: UIColor {
    if #available(iOS 11.0, *),
       let color = UIColor(named: ColorAsset.deleteAction.rawValue) {
      return color
    }

    return .systemRed
  }
  
  static var fieldBackgroundColor: UIColor {
    if #available(iOS 11.0, *),
       let color = UIColor(named: ColorAsset.fieldBackground.rawValue) {
      return color
    }

    return .white
  }
  
  static var fieldBorderColor: UIColor {
    if #available(iOS 11.0, *),
       let color = UIColor(named: ColorAsset.fieldBorder.rawValue) {
      return color
    }

    return .lightGray
  }
  
  static var fieldTextColor: UIColor {
    if #available(iOS 11.0, *),
       let color = UIColor(named: ColorAsset.fieldText.rawValue) {
      return color
    }

    return .lightGray
  }
  
  static var progressBarBackgroundColor: UIColor {
    if #available(iOS 11.0, *),
       let color = UIColor(named: ColorAsset.progressBarBackground.rawValue) {
      return color
    }

    return .black
  }
}
