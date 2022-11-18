//
//  NYPLEPUBOpener.swift
//  Simplified
//
//  Created by Ettore Pasquini on 11/17/22.
//  Copyright © 2022 NYPL. All rights reserved.
//

import Foundation

class NYPLEPUBOpener: NSObject {
  @objc
  func open(_ book: NYPLBook, successCompletion: @escaping () -> Void) {

    let url = NYPLMyBooksDownloadCenter.shared()?
      .fileURL(forBookIndentifier: book.identifier)

    let currentAccountDetails = AccountsManager.shared.currentAccount?.details
    let syncPermission = currentAccountDetails?.syncPermissionGranted ?? false
    let rootTabController = NYPLRootTabBarController.shared()
    rootTabController?.presentBook(book,
                                   fromFileURL: url,
                                   syncPermission: syncPermission,
                                   successCompletion: successCompletion)
    
    rootTabController?.annotationsSynchronizer?
      .checkServerSyncStatus(settings: NYPLSettings.shared,
                             syncPermissionGranted: syncPermission) { enableSync, error in
        guard error == nil else {
          return
        }

        currentAccountDetails?.syncPermissionGranted = enableSync;
      }
  }
}
