class SEUtils {
  class func vcSwitchLibrary(context: UINavigationController, accountSwitchLogic: ((Account) -> Void)?) {
    let vc = context.visibleViewController
    let style = (vc != nil) ? UIAlertController.Style.actionSheet : UIAlertController.Style.alert

    let alert = UIAlertController.init(title: NSLocalizedString("PickYourLibrary", comment: ""), message: nil, preferredStyle: style)
    alert.popoverPresentationController?.barButtonItem = vc?.navigationItem.leftBarButtonItem
    alert.popoverPresentationController?.permittedArrowDirections = .up
    
    let accounts = NYPLSettings.shared.settingsAccountsList
    
    for acct in accounts {
      guard let account = AccountsManager.shared.account(acct) else {
        continue
      }
      
      alert.addAction(UIAlertAction.init(title: account.name, style: .default, handler: { (action) in
        var workflowsInProgress = NYPLBookRegistry.shared()?.syncing ?? false
#if FEATURE_DRM_CONNECTOR
        workflowsInProgress = workflowsInProgress || (NYPLADEPT.sharedInstance()?.workflowsInProgress ?? false)
#endif

        if workflowsInProgress {
          context.present(NYPLAlertUtils.alert(title: "PleaseWait", message: "PleaseWaitMessage"), animated: true, completion: nil)
        } else {
          accountSwitchLogic?.self(account)
        }
      }))
    }
    
    alert.addAction(UIAlertAction.init(title: NSLocalizedString("ManageAccounts", comment: ""), style: .default, handler: { (action) in
      let tabCount = NYPLRootTabBarController.shared()?.viewControllers?.count ?? 1
      let splitViewVC = NYPLRootTabBarController.shared()?.viewControllers?.last as? UISplitViewController
      let masterNavVC = splitViewVC?.viewControllers.first as? UINavigationController
      masterNavVC?.popToRootViewController(animated: false)
      NYPLRootTabBarController.shared()?.selectedIndex = tabCount - 1
      let tableVC = masterNavVC?.viewControllers.first as? NYPLSettingsPrimaryTableViewController
      tableVC?.tableView.selectRow(at: IndexPath.init(row: 0, section: 0), animated: true, scrollPosition: .middle)
    }))
    
    alert.addAction(UIAlertAction.init(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
    
    NYPLRootTabBarController.shared()?.safelyPresentViewController(alert, animated: true, completion: nil)
  }
}
