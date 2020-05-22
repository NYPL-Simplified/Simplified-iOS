//
//  NYPLSignInBusinessLogic.swift
//  Simplified
//
//  Created by Ettore Pasquini on 5/5/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import UIKit

class NYPLSignInBusinessLogic: NSObject {

  @objc let libraryAccountID: String
  private let permissionsCheckLock = NSLock()
  @objc let requestTimeoutInterval: TimeInterval = 25.0

  @objc init(libraryAccountID: String) {
    self.libraryAccountID = libraryAccountID
    super.init()
  }

  @objc var libraryAccount: Account? {
    return AccountsManager.shared.account(libraryAccountID)
  }

  @objc var userAccount: NYPLUserAccount {
    return NYPLUserAccount.sharedAccount(libraryUUID: libraryAccountID)
  }

  @objc func librarySupportsBarcodeDisplay() -> Bool {
    // For now, only supports libraries granted access in Accounts.json,
    // is signed in, and has an authorization ID returned from the loans feed.
    return userAccount.hasBarcodeAndPIN() &&
      userAccount.authorizationIdentifier != nil &&
      (libraryAccount?.details?.supportsBarcodeDisplay ?? false)
  }

  @objc func isSignedIn() -> Bool {
    return userAccount.hasBarcodeAndPIN()
  }

  @objc func registrationIsPossible() -> Bool {
    return !isSignedIn() && NYPLConfiguration.cardCreationEnabled() && libraryAccount?.details?.signUpUrl != nil
  }

  @objc func juvenileCardsManagementIsPossible() -> Bool {
    guard NYPLConfiguration.cardCreationEnabled() else {
      return false
    }
    guard libraryAccount?.details?.supportsCardCreator ?? false else {
      return false
    }

    return isSignedIn()
  }

  @objc func shouldShowEULALink() -> Bool {
    return libraryAccount?.details?.getLicenseURL(.eula) != nil
  }

  @objc func shouldShowSyncButton() -> Bool {
    guard let libraryDetails = libraryAccount?.details else {
      return false
    }

    return libraryDetails.supportsSimplyESync &&
      libraryDetails.getLicenseURL(.annotations) != nil &&
      userAccount.hasBarcodeAndPIN() &&
      libraryAccountID == AccountsManager.shared.currentAccount?.uuid
  }

  /// Updates server sync setting for the currently selected library.
  /// - Parameters:
  ///   - granted: Whether the user is granting sync permission or not.
  ///   - postServerSyncCompletion: Only run when granting sync permission.
  @objc func changeSyncPermission(to granted: Bool,
                                  postServerSyncCompletion: @escaping (Bool) -> Void) {
    if granted {
      // When granting, attempt to enable on the server.
      NYPLAnnotations.updateServerSyncSetting(toEnabled: true) { success in
        self.libraryAccount?.details?.syncPermissionGranted = success
        postServerSyncCompletion(success)
      }
    } else {
      // When revoking, just ignore the server's annotations.
      libraryAccount?.details?.syncPermissionGranted = false
    }
  }


  /// Checks with the annotations sync status with the server, adding logic
  /// to make sure only one such requests is being executed at a time.
  /// - Parameters:
  ///   - preWork: Any preparatory work to be done. This block is run
  ///   synchronously on the main thread. It's not run at all if a request is
  ///   already ongoing or if the current library doesn't support syncing.
  ///   - postWork: Any final work to be done. This block is run
  ///   on the main thread. It's not run at all if a request is
  ///   already ongoing or if the current library doesn't support syncing.
  @objc func checkSyncPermission(preWork: () -> Void,
                                 postWork: @escaping (_ enableSync: Bool) -> Void) {
    guard let libraryDetails = libraryAccount?.details else {
      return
    }

    guard permissionsCheckLock.try(), libraryDetails.supportsSimplyESync else {
      Log.debug(#file, "Skipping sync setting check. Request already in progress or sync not supported.")
      return
    }

    NYPLMainThreadRun.sync {
      preWork()
    }

    NYPLAnnotations.requestServerSyncStatus(forAccount: userAccount) { enableSync in
      if enableSync {
        libraryDetails.syncPermissionGranted = true
      }

      NYPLMainThreadRun.sync {
        postWork(enableSync)
      }

      self.permissionsCheckLock.unlock()
    }
  }
}
