//
//  NYPLSettingsSplitViewController.swift
//  SimplyE / Open eBooks
//
//  Created by Kyle Sakai.
//  Copyright © 2020 NYPL. All rights reserved.
//

/// Currently used only by Open eBooks, but extendable for use in SimplyE.
/// - Seealso: https://github.com/NYPL-Simplified/Simplified-iOS/pull/1070
/// TODO: SIMPLY-3053
class NYPLSettingsSplitViewController : UISplitViewController, UISplitViewControllerDelegate {
  private var isFirstLoad: Bool
  private var currentLibraryAccountProvider: NYPLCurrentLibraryAccountProvider
  
  @objc init(currentLibraryAccountProvider: NYPLCurrentLibraryAccountProvider) {
    self.isFirstLoad = true
    self.currentLibraryAccountProvider = currentLibraryAccountProvider
    let navVC = UINavigationController.init(rootViewController: NYPLSettingsPrimaryTableViewController())
    super.init(nibName: nil, bundle: nil)
    
    self.delegate = self
    self.title = NSLocalizedString("Settings", comment: "")
    self.tabBarItem.image = UIImage.init(named: "Settings")
    self.viewControllers = [navVC]
    self.presentsWithGesture = false
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  var primaryTableVC: NYPLSettingsPrimaryTableViewController? {
    let navVC = self.viewControllers.first as? UINavigationController
    return navVC?.viewControllers.first as? NYPLSettingsPrimaryTableViewController
  }

  // MARK: UIViewController

  override func viewDidLoad() {
    super.viewDidLoad()
    self.preferredDisplayMode = .allVisible

    configPrimaryVCItems(using:
      NYPLLibraryAccountURLsProvider(account:
        currentLibraryAccountProvider.currentAccount))
  }
  
  // MARK: UISplitViewControllerDelegate

  func splitViewController(_ splitVC: UISplitViewController,
                           collapseSecondary secondaryVC: UIViewController,
                           onto primaryVC: UIViewController) -> Bool {
    let rVal = self.isFirstLoad
    self.isFirstLoad = false
    return rVal
  }
}
