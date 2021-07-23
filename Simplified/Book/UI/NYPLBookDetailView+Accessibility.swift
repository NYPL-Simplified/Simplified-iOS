//
//  NYPLBookDetailView+Accessibility.swift
//  Simplified
//
//  Created by Ernest Fan on 2021-07-21.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import UIKit

@objc extension NYPLBookDetailView {
  @objc(setUIAccessibilityFocusToView:)
  func setUIAccessibilityFocus(to view: UIView) {
    NYPLMainThreadRun.asyncIfNeeded {
      if UIAccessibility.isVoiceOverRunning {
        UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: view)
      }
    }
  }
}
