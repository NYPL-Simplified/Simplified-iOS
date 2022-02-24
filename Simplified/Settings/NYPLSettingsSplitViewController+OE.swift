//
//  NYPLSettingsSplitViewController+OE.swift
//  Open eBooks
//
//  Created by Kyle Sakai.
//  Copyright © 2020 NYPL. All rights reserved.
//

import Foundation

// The reason why this is here instead of directly inside the same source file
// of NYPLSettingsSplitViewController is because the latter is meant as a
// foundation for both SimplyE and Open eBooks, while this extension is
// only meant for Open eBooks.
// - See: https://github.com/NYPL-Simplified/Simplified-iOS/pull/1070
extension NYPLSettingsSplitViewController {

  /// Sets up the items of the `primaryTableVC`.
  func configPrimaryVCItems(using URLsProvider: NYPLLibraryAccountURLsProvider) {
    let splitVC = self
    splitVC.primaryTableVC?.items = [
      NYPLSettingsPrimaryTableItem.init(
        indexPath: IndexPath(row: 0, section: 0),
        title: NSLocalizedString("Account", comment: "Title for account section"),
        selectionHandler: { (splitVC, tableVC) in
          if NYPLUserAccount.sharedAccount().hasCredentials(),
            let currentLibraryID = AccountsManager.shared.currentAccountId {

            splitVC.showDetailViewController(
              NYPLSettingsPrimaryTableItem.handleVCWrap(
                NYPLSettingsAccountDetailViewController(
                  libraryAccountID: currentLibraryID
                )
              ),
              sender: nil
            )
          } else {
            OETutorialChoiceViewController.showLoginPicker(handler: nil)
          }
      }
      ),
      NYPLSettingsPrimaryTableItem.init(
        indexPath: IndexPath(row: 0, section: 1),
        title: NSLocalizedString("EULA", comment: "Title for User Agreement section"),
        viewController: NYPLSettingsPrimaryTableItem.generateRemoteView(
          title: NSLocalizedString("EULA", comment: "Title for User Agreement section"),
          url: URLsProvider.accountURL(forType: .eula)
        )
      ),
      NYPLSettingsPrimaryTableItem.init(
        indexPath: IndexPath(row: 1, section: 1),
        title: NSLocalizedString("PrivacyPolicy", comment: "Title for Privacy Policy section"),
        viewController: NYPLSettingsPrimaryTableItem.generateRemoteView(
          title: NSLocalizedString("PrivacyPolicy", comment: "Title for Privacy Policy section"),
          url: URLsProvider.accountURL(forType: .privacyPolicy)
        )
      ),
      NYPLSettingsPrimaryTableItem.init(
        indexPath: IndexPath(row: 2, section: 1),
        title: NSLocalizedString("Acknowledgements", comment: "Title for acknowledgements section"),
        viewController: NYPLSettingsPrimaryTableItem.generateRemoteView(
          title: NSLocalizedString("Acknowledgements", comment: "Title for acknowledgements section"),
          url: URLsProvider.accountURL(forType: .acknowledgements)
        )
      ),
      NYPLSettingsPrimaryTableItem.init(
        indexPath: IndexPath(row: 3, section: 1),
        title: NSLocalizedString("SoftwareLicenses", comment: "Title for software licenses section"),
        viewController: NYPLSettingsPrimaryTableItem.generateLocalWebView(
          title: NSLocalizedString("SoftwareLicenses", comment: "Title for software licenses section"),
          fileURL: Bundle.main.url(forResource: "software-licenses", withExtension: "html") ?? URL(string: "https://openebooks.net")!
        )
      )
    ]
  }
}
