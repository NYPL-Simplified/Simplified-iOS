//
//  NYPLSignInModalFactory.swift
//  Simplified
//
//  Created by Ettore Pasquini on 6/23/22.
//  Copyright © 2022 NYPL. All rights reserved.
//

import UIKit

/// This class abstract out which sign-in modal should be presented depending
/// on the situation, including compile-time contexts such as which app we
/// are building.
class NYPLSignInModalFactory {
  private let usingExistingCredentials: Bool
  private let forceEditability: Bool
  private let modalCompletion: ((_ isSignedIn: Bool) -> Void)?

  init(usingExistingCredentials: Bool = false,
       forceEditability: Bool = false,
       modalCompletion: ((_ isSignedIn: Bool) -> Void)?) {
    self.usingExistingCredentials = usingExistingCredentials
    self.forceEditability = forceEditability
    self.modalCompletion = modalCompletion
  }

  #if SIMPLYE

  private var signInVC: NYPLAccountSignInViewController?

  func refreshAuthentication() {
    signInVC = NYPLAccountSignInViewController()
    signInVC?.forceEditability = forceEditability
    signInVC?.presentIfNeeded(usingExistingCredentials: usingExistingCredentials) { [weak self] in
      // passing `true` because this `presentIfNeeded` refresh completion is
      // only called in case of success
      self?.modalCompletion?(true)
      self?.signInVC = nil
    }
  }

  #elseif OPENEBOOKS

  private var signInVC: UIViewController?

  func refreshAuthentication() {
    guard let libraryAccount = AccountsManager.shared.currentAccount else {
      NYPLAlertUtils.presentUnrecoverableAlert(for: "Unable to get library Account instance after selecting First Book as login choice")
      return
    }

    let userAccount = NYPLUserAccount.sharedAccount()

    let vc: UIViewController
    let authLogic: NYPLSignInBusinessLogic
    if userAccount.authDefinition?.authType == .oauthClientCredentials {
      vc = OELoginFirstBookVC(libraryAccount: libraryAccount,
                              postLoginConfigurator: self)
      authLogic = (vc as! OELoginFirstBookVC).businessLogic
    } else {
      vc = OECleverReauthenticatorVC(libraryAccount: libraryAccount,
                                     postLoginConfigurator: self)
      authLogic = (vc as! OECleverReauthenticatorVC).businessLogic
    }

    signInVC = vc

    // since `refreshAuthIfNeeded(usingExistingCredentials:)` interfaces with
    // UI code, and at this point we have not yet presented the UI, make sure
    // we have the view objects created before that
    _ = vc.view

    let shouldPresent = authLogic
      .refreshAuthIfNeeded(usingExistingCredentials: usingExistingCredentials)

    if shouldPresent {
      self.presentAsModal(vc)
    }
  }

  private func presentAsModal(_ vc: UIViewController) {
    let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel,
                                       target: self,
                                       action: #selector(didSelectCancel))
    vc.navigationItem.leftBarButtonItem = cancelButton

    let navVC = UINavigationController(rootViewController: vc)
    navVC.modalPresentationStyle = .formSheet
    NYPLPresentationUtils.safelyPresent(navVC)
  }
  #endif

  @objc func didSelectCancel() {
    signInVC?.dismiss(animated: true) { [weak self] in
      // passing `false` because we know reauthentication is required, but
      // user chose to cancel
      self?.modalCompletion?(false)
      self?.signInVC = nil
    }
  }
}

#if OPENEBOOKS
extension NYPLSignInModalFactory: OEAppUIStructureConfigurating {
  @objc func setUpRootVC(userIsSignedIn: Bool) {
    Log.debug(#function, "About to call loginCompletion after refreshing authentication, userIsSignedIn=\(userIsSignedIn)")
    modalCompletion?(userIsSignedIn)
    signInVC?.dismiss(animated: true) { [weak self] in
      self?.signInVC = nil
    }
  }
}
#endif
