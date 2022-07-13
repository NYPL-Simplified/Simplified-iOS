//
//  NYPLConfiguration+Color.swift
//  Simplified
//
//  Created by Ernest Fan on 2021-09-16.
//  Copyright © 2021 NYPL. All rights reserved.
//

import Foundation

private enum ColorAsset: String {
  case primaryBackground
  case primaryText
  case secondaryBackground
  case secondaryText
  case action
  case touchDownAction
  case buttonBackground
  case deleteAction
  case fieldBorder
  case disabledFieldText
  case progressBarBackground
  case shadow
}

@objc extension NYPLConfiguration {
  static var primaryBackgroundColor: UIColor {
    if #available(iOS 13.0, *),
       UIScreen.main.traitCollection.userInterfaceStyle == .light {
      return .systemBackground
    } else if #available(iOS 11.0, *),
              let color = UIColor(named: ColorAsset.primaryBackground.rawValue) {
      return color
    }

    return .white
  }
  
  static var primaryTextColor: UIColor {
    if #available(iOS 13.0, *),
       UIScreen.main.traitCollection.userInterfaceStyle == .light {
      return .label
    } else if #available(iOS 11.0, *),
              let color = UIColor(named: ColorAsset.primaryText.rawValue) {
      return color
    }

    return .black
  }

  static var secondaryBackgroundColor: UIColor {
    if #available(iOS 13.0, *),
       UIScreen.main.traitCollection.userInterfaceStyle == .light {
      return .secondarySystemBackground
    } else if #available(iOS 11.0, *),
              let color = UIColor(named: ColorAsset.secondaryBackground.rawValue) {
      return color
    }
    
    return .lightGray
  }
  
  static var secondaryTextColor: UIColor {
    if #available(iOS 13.0, *),
       UIScreen.main.traitCollection.userInterfaceStyle == .light {
      return .secondaryLabel
    } else if #available(iOS 11.0, *),
              let color = UIColor(named: ColorAsset.secondaryText.rawValue) {
      return color
    }

    return .black
  }
  
  static var actionColor: UIColor {
    if #available(iOS 13.0, *),
       UIScreen.main.traitCollection.userInterfaceStyle == .light {
      return .link
    } else if #available(iOS 11.0, *),
              let color = UIColor(named: ColorAsset.action.rawValue) {
      return color
    }

    return .systemBlue
  }

  static var touchDownActionColor: UIColor {
    if #available(iOS 11.0, *),
       let color = UIColor(named: ColorAsset.touchDownAction.rawValue) {
      return color
    }

    return .blue
  }

  static var buttonBackgroundColor: UIColor {
    if #available(iOS 11.0, *),
       let color = UIColor(named: ColorAsset.buttonBackground.rawValue) {
      return color
    } else {
      return primaryBackgroundColor
    }
  }

  static var deleteActionColor: UIColor {
    if #available(iOS 11.0, *),
       let color = UIColor(named: ColorAsset.deleteAction.rawValue) {
      return color
    }

    return .systemRed
  }
  
  static var fieldBorderColor: UIColor {
    if #available(iOS 11.0, *),
       let color = UIColor(named: ColorAsset.fieldBorder.rawValue) {
      return color
    }

    return .lightGray
  }
  
  static var disabledFieldTextColor: UIColor {
    if #available(iOS 11.0, *),
       let color = UIColor(named: ColorAsset.disabledFieldText.rawValue) {
      return color
    }

    return .lightGray
  }

  static var shadowColor: UIColor {
    if #available(iOS 11.0, *),
       let color = UIColor(named: ColorAsset.shadow.rawValue) {
      return color
    }

    return .darkGray
  }

  static var progressBarBackgroundColor: UIColor {
    if #available(iOS 11.0, *),
       let color = UIColor(named: ColorAsset.progressBarBackground.rawValue) {
      return color
    }

    return .black
  }
  
  static var transparentBackgroundColor: UIColor {
    if #available(iOS 12.0, *),
       UIScreen.main.traitCollection.userInterfaceStyle == .dark {
      return UIColor(white: 0.2, alpha: 0.7)
    } else {
      return UIColor(white: 0, alpha: 0.7)
    }
  }
}
