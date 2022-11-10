//
//  NYPLRootTabBarController+Common.swift
//  Simplified
//
//  Created by Ettore Pasquini on 11/9/22.
//  Copyright © 2022 NYPL. All rights reserved.
//

import Foundation

extension NYPLRootTabBarController {
  @objc func makeR2Owner() -> NYPLR2Owner {
    return NYPLR2Owner(bookRegistry: NYPLBookRegistry.shared(),
                       annotationsSynchronizer: NYPLAnnotations.self)
  }
}
