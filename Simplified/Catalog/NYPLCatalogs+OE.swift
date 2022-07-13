//
//  NYPLCatalogNavigationController+OE.swift
//  Open eBooks
//
//  Created by Ettore Pasquini on 9/14/20.
//  Copyright © 2020 NYPL. All rights reserved.
//

import Foundation

extension NYPLCatalogNavigationController {
  @objc func didSignOut() {
    NYPLMainThreadRun.asyncIfNeeded { [self] in
      popToRootViewController(animated: true)
      loadTopLevelCatalogViewController()
    }
  }
}

extension NYPLCatalogFeedViewController {
  @objc func shouldLoad() -> Bool {
    return NYPLUserAccount.sharedAccount().isSignedIn()
  }
}
