//
//  NYPLSignInBusinessLogic.swift
//  Simplified
//
//  Created by Ettore Pasquini on 5/5/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import UIKit
import NYPLCardCreator

class NYPLSignInBusinessLogic: NSObject {

  @objc let libraryAccountID: String
  private let permissionsCheckLock = NSLock()
  @objc let requestTimeoutInterval: TimeInterval = 25.0

  private let juvenileAuthLock = NSLock()
  @objc private(set) var juvenileAuthIsOngoing = false
  let juvenileCardCreationCoordinator: JuvenileFlowCoordinator

  /// The configuration for the regular sign-up flow.
  @objc let cardCreatorConfiguration: CardCreatorConfiguration

  @objc init(libraryAccountID: String) {
    self.libraryAccountID = libraryAccountID

    let libAcct = NYPLSignInBusinessLogic.sharedLibraryAccount(libraryAccountID)
    let simplifiedBaseURL = libAcct?.details?.signUpUrl ?? APIKeys.cardCreatorEndpointURL

    // the likeliness of this username/password to be nil is close to zero
    // because these strings are decoded from static byte arrays. So any error
    // should be detected during QA. Even in the case where these are nil, by
    // using the "" default for initializing the CardCreatorConfiguration (see
    // below) we'll run into an error soon after, at the 1st screen of the flow.
    if NYPLSecrets.cardCreatorUsername == nil {
      NYPLErrorLogger.logError(withCode: NYPLErrorCode.cardCreatorCredentialsDecodeFail,
                               context: NYPLErrorLogger.Context.signUp.rawValue,
                               message: "Unable to decode cardCreator username")
    }
    if NYPLSecrets.cardCreatorPassword == nil {
      NYPLErrorLogger.logError(withCode: NYPLErrorCode.cardCreatorCredentialsDecodeFail,
                               context: NYPLErrorLogger.Context.signUp.rawValue,
                               message: "Unable to decode cardCreator password")
    }

    cardCreatorConfiguration = CardCreatorConfiguration(
      endpointURL: simplifiedBaseURL,
      endpointVersion: APIKeys.cardCreatorVersion,
      endpointUsername: NYPLSecrets.cardCreatorUsername ?? "",
      endpointPassword: NYPLSecrets.cardCreatorPassword ?? "",
      requestTimeoutInterval: requestTimeoutInterval)

    // for juvenile flow
    let platformAPI = NYPLPlatformAPIInfo(
      oauthTokenURL: APIKeys.PlatformAPI.oauthTokenURL,
      clientID: NYPLSecrets.clientID,
      clientSecret: NYPLSecrets.clientSecret,
      baseURL: APIKeys.PlatformAPI.baseURL)
    let config = CardCreatorConfiguration(
      endpointURL: simplifiedBaseURL,
      endpointVersion: APIKeys.cardCreatorVersion,
      endpointUsername: NYPLSecrets.cardCreatorUsername ?? "",
      endpointPassword: NYPLSecrets.cardCreatorPassword ?? "",
      juvenilePlatformAPIInfo: platformAPI,
      requestTimeoutInterval: requestTimeoutInterval)
    juvenileCardCreationCoordinator = JuvenileFlowCoordinator(configuration: config)

    super.init()
  }

  private static func sharedLibraryAccount(_ libAccountID: String) -> Account? {
    return AccountsManager.shared.account(libAccountID)
  }

  @objc var libraryAccount: Account? {
    return NYPLSignInBusinessLogic.sharedLibraryAccount(libraryAccountID)
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
    guard libraryAccountID == AccountsManager.NYPLAccountUUID else {
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

  @objc
  func startJuvenileCardCreation(
    eligibilityCompletion: @escaping (UINavigationController?, Error?) -> Void,
    flowCompletion: @escaping () -> Void) {

    guard juvenileAuthLock.try() else {
      // not calling any completion because this means a flow is already going
      return
    }

    juvenileAuthIsOngoing = true

    guard let barcode = userAccount.barcode else {
      let description = NSLocalizedString("We are unable to read your library card, which is necessary in order to create a dependent card.", comment: "Message describing the fact that a patron's barcode is not readable and therefore we cannot create a dependent juvenile card")
      let recoveryMsg = NSLocalizedString("Try to sign out, sign back in, then try again.", comment: "An error recovery suggestion")

      let error = NSError(domain: NYPLSimplyEDomain,
                          code: NYPLErrorCode.missingParentBarcodeForJuvenile.rawValue,
                          userInfo: [
                            NSLocalizedDescriptionKey: description,
                            NSLocalizedRecoverySuggestionErrorKey: recoveryMsg])
      NYPLErrorLogger.logError(error)
      eligibilityCompletion(nil, error)
      juvenileAuthIsOngoing = false
      juvenileAuthLock.unlock()
      return
    }

    juvenileCardCreationCoordinator.configuration.completionHandler = { _, _, _ in
      flowCompletion()
    }

    juvenileCardCreationCoordinator.startJuvenileFlow(parentBarcode: barcode) { [weak self] result in
      switch result {
      case .success(let navVC):
        eligibilityCompletion(navVC, nil)
      case .fail(let error):
        NYPLErrorLogger.logError(error)
        eligibilityCompletion(nil, error)
      }
      self?.juvenileAuthIsOngoing = false
      self?.juvenileAuthLock.unlock()
    }
  }
}
