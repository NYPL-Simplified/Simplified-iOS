//
//  NYPLSettingsSplitViewController.swift
//  SimplyE / Open eBooks
//
//  Created by Kyle Sakai.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

/// Currently used only by Open eBooks, but extendable for use in SimplyE.
/// - Seealso: https://github.com/NYPL-Simplified/Simplified-iOS/pull/1070
class NYPLSettingsSplitViewController : UISplitViewController, UISplitViewControllerDelegate {
  private var isFirstLoad: Bool
  
  init() {
    self.isFirstLoad = true
    let navVC = UINavigationController.init(rootViewController: NYPLSettingsPrimaryTableViewController())
    super.init(nibName: nil, bundle: nil)
    
    self.delegate = self
    self.title = NSLocalizedString("Settings", comment: "")
    self.tabBarItem.image = UIImage.init(named: "Settings")
    self.viewControllers = [navVC]
    self.presentsWithGesture = false
    configSettingsTab()
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  var primaryTableVC: NYPLSettingsPrimaryTableViewController? {
    let navVC = self.viewControllers.first as? UINavigationController
    return navVC?.viewControllers.first as? NYPLSettingsPrimaryTableViewController
  }

  // MARK: UIView

  override func viewDidLoad() {
    super.viewDidLoad()
    self.preferredDisplayMode = .allVisible
  }
  
  // MARK: UISplitViewControllerDelegate

  func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
    let rVal = self.isFirstLoad
    self.isFirstLoad = false
    return rVal
  }
}
