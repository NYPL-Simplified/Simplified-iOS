//
//  NYPLBookRegistryMock.swift
//  Simplified
//
//  Created by Ettore Pasquini on 10/14/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation
@testable import SimplyE

class NYPLBookRegistryMock: NSObject, NYPLBookRegistrySyncing {
  var syncing = false

  func reset(_ libraryAccountUUID: String) {
    syncing = false
  }

  func syncResettingCache(_ resetCache: Bool,
                          completionHandler: (([AnyHashable : Any]?) -> Void)?) {
    syncing = true
    DispatchQueue.global(qos: .background).async {
      self.syncing = false
      completionHandler?(nil)
    }
  }

  func save() {
  }
}
