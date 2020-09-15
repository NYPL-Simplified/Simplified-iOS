//
//  NYPLRootTabBarController+OE.swift
//  Simplified
//
//  Created by Ettore Pasquini on 9/10/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

extension NYPLRootTabBarController: UITabBarControllerDelegate {

  @objc(tabBarController:didSelectViewController:)
  func tabBarController(_ tabBarController: UITabBarController,
                        didSelect vc: UIViewController) {
    guard NYPLUserAccount.sharedAccount().isSignedIn() else {
      OETutorialChoiceViewController.showLoginPicker(handler: nil)
      return
    }
  }
}
