//
//  NYPLCatalogNavigationController+SE.swift
//  Simplified
//
//  Created by Ettore Pasquini on 9/14/20.
//  Copyright © 2020 NYPL. All rights reserved.
//

import Foundation

extension NYPLCatalogNavigationController {
  @objc func didSignOut() {
  }
}

extension NYPLCatalogFeedViewController {
  @objc func shouldLoad() -> Bool {
    return NYPLSettings.shared.userHasSeenWelcomeScreen
  }
}
