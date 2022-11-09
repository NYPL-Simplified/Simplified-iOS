//
//  NYPLRootTabBarController+Common.swift
//  Simplified
//
//  Created by Ettore Pasquini on 11/9/22.
//  Copyright © 2022 NYPL. All rights reserved.
//

import Foundation

extension NYPLRootTabBarController {
  @objc func createR2Owner() -> NYPLR2Owner {
    let lastReadSyncer = NYPLLastReadPositionSynchronizer(
      bookRegistry: NYPLBookRegistry.shared())

    return NYPLR2Owner(lastReadPositionSynchronizer: lastReadSyncer)
  }
}
