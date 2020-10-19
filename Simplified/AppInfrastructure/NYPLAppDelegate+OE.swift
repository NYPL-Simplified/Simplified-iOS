//
//  NYPLAppDelegate+OE.swift
//  Open eBooks
//
//  Created by Ettore Pasquini on 9/17/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

extension NYPLAppDelegate {
  @objc func setUpRootVC() {
    if NYPLSettings.shared.userHasAcceptedEULA {
      if NYPLSettings.shared.userHasSeenWelcomeScreen {
        window.rootViewController = NYPLRootTabBarController.shared()
      } else {
        window.rootViewController = OETutorialViewController()
      }
    } else {
      let eulaURL = URL(string: "https://openebooks.net/app_user_agreement.html")!
      let eulaVC = NYPLEULAViewController(onlineEULAURL: eulaURL) {
        UIView.transition(
          with: self.window,
          duration: 0.5,
          options: [.transitionCurlUp, .allowAnimatedContent, .layoutSubviews],
          animations: {
            self.window?.rootViewController = OETutorialViewController()
        },
          completion: nil
        )
      }
      let eulaNavController = UINavigationController(rootViewController: eulaVC)
      self.window?.rootViewController = eulaNavController
    }
  }

  @objc func completeBecomingActive() {
    if !NYPLUserAccount.sharedAccount().hasCredentials()
      && NYPLSettings.shared.userHasSeenWelcomeScreen {
      
      OETutorialChoiceViewController.showLoginPicker(handler: nil)
    }
  }

  /// Handle all custom URL schemes specific to Open eBooks here.
  /// - Parameter url: The URL to process.
  /// - Returns: `true` if the app should handle the URL because it matches a
  /// custom URL scheme we're registered to.
  @objc(shouldHandleAppSpecificCustomURLSchemesForURL:)
  func shouldHandleAppSpecificCustomURLSchemes(for url: URL) -> Bool {
    if let scheme = url.scheme {
      if scheme == "open-ebooks-clever" {
        NotificationCenter.default
          .post(name: .NYPLAppDelegateDidReceiveCleverRedirectURL,
                object: url)
        return true
      }
    }

    return false
  }
}
