//
//  NYPLSettingsSplitViewController+SE.swift
//  Simplified
//
//  Created by Ettore Pasquini on 10/2/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

extension NYPLLibraryAccountURLsProvider{

  func fallback(forURLType urlType: URLType) -> URL {
    // provide some reasonable defaults if we can't find a URL
    switch urlType {
    case .acknowledgements:
      return URL(string: "https://openebooks.net/app_acknowledgments.html")!
    case .eula:
      return URL(string: "https://openebooks.net/app_user_agreement.html")!
    case .privacyPolicy:
      return URL(string: "https://openebooks.net/app_privacy.html")!
    default:
      // should never happen for OE
      return URL(string: "https://openebooks.net")!
    }
  }
}

extension NYPLSettingsSplitViewController {

  /// Sets up the items of the `primaryTableVC`.
  func configPrimaryVCItems(using URLsProvider: NYPLLibraryAccountURLsProvider) {
    let splitVC = self

    splitVC.primaryTableVC?.items = [
      NYPLSettingsPrimaryTableItem.init(
        indexPath: IndexPath(row: 0, section: 0),
        title: NSLocalizedString("Accounts", comment: "Title for SimplyE accounts item"),
        selectionHandler: { (splitVC, tableVC) in
          let accounts = NYPLSettings.shared.settingsAccountsList

          splitVC.showDetailViewController(
            NYPLSettingsPrimaryTableItem.handleVCWrap(
              NYPLSettingsAccountsTableViewController(accounts: accounts)
            ),
            sender: nil
          )
      }
      ),
      NYPLSettingsPrimaryTableItem.init(
        indexPath: IndexPath(row: 0, section: 1),
        title: NSLocalizedString("AboutApp", comment: "Title for About SimplyE item"),
        viewController: NYPLSettingsPrimaryTableItem.generateRemoteView(
          title: NSLocalizedString("AboutApp", comment: "Title for About SimplyE item"),
          url: URLsProvider.accountURL(forType: .acknowledgements)
        )
      ),
      NYPLSettingsPrimaryTableItem.init(
        indexPath: IndexPath(row: 1, section: 1),
        title: NSLocalizedString("EULA", comment: "Title for User Agreement item"),
        viewController: NYPLSettingsPrimaryTableItem.generateRemoteView(
          title: NSLocalizedString("EULA", comment: "Title for User Agreement item"),
          url: URLsProvider.accountURL(forType: .eula)
        )
      ),
      NYPLSettingsPrimaryTableItem.init(
        indexPath: IndexPath(row: 2, section: 1),
        title: NSLocalizedString("SoftwareLicenses", comment: "Title for Software Licenses item"),
        viewController: NYPLSettingsPrimaryTableItem.generateBundledView(
          title: NSLocalizedString("Privacy Policy", comment: "Title for Privacy Policy item"),
          url: Bundle.main.url(forResource: "software-licenses",
                               withExtension: "html")
        )
      )
    ]
  }

}
