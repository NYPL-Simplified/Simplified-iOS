//
//  NYPLAppDelegate+OE.swift
//  Open eBooks
//
//  Created by Ettore Pasquini on 9/17/20.
//  Copyright © 2020 NYPL. All rights reserved.
//

import Foundation

@objc protocol OEAppUIStructureConfigurating {

  /// - Parameter userIsSignedIn: Pass `true` if this is called after a
  /// successful login; pass `false` in all other cases.
  @objc func setUpRootVC(userIsSignedIn: Bool)
}

extension NYPLAppDelegate: OEAppUIStructureConfigurating {
  @objc func setUpRootVC(userIsSignedIn: Bool) {
    if NYPLSettings.shared.userHasAcceptedEULA {
      if NYPLSettings.shared.userHasSeenWelcomeScreen, userIsSignedIn {
        window.rootViewController = NYPLRootTabBarController.shared()
      } else {
        window.rootViewController = createLoginNavController()
        NYPLSettings.shared.userHasSeenWelcomeScreen = true
      }
    } else {
      let eulaVC = OEEULAViewController() {
        UIView.transition(
          with: self.window,
          duration: 0.5,
          options: [.transitionCurlUp, .allowAnimatedContent, .layoutSubviews],
          animations: {
            self.window?.rootViewController = self.createLoginNavController()
        },
          completion: nil
        )
      }
      let eulaNavController = UINavigationController(rootViewController: eulaVC)
      self.window?.rootViewController = eulaNavController
    }
  }

  private func createLoginNavController() -> UINavigationController {
    let vc = OELoginChoiceViewController(postLoginConfigurator: self)
    return UINavigationController(rootViewController: vc)
  }
}

extension NYPLAppDelegate {
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
