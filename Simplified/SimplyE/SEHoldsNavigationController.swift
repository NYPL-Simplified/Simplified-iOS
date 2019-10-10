class SEHoldsNavigationController : NYPLHoldsNavigationController {
  override init() {
    super.init()
    self.topViewController?.navigationItem.leftBarButtonItem = UIBarButtonItem.init(image: UIImage.init(named: "Catalog"), style: .plain, target: self, action: #selector(switchLibrary))
    self.topViewController?.navigationItem.leftBarButtonItem?.accessibilityLabel = NSLocalizedString("AccessibilitySwitchLibrary", tableName: "", comment: "")
    self.topViewController?.navigationItem.leftBarButtonItem?.isEnabled = true
  }
  
  @objc func switchLibrary() {
    SEUtils.vcSwitchLibrary(context: self) { (account) in
      NYPLBookRegistry.shared()?.save()
      AccountsManager.sharedInstance().currentAccount = account

      let catalog = NYPLRootTabBarController.shared()?.viewControllers?.first as? NYPLCatalogNavigationController
      catalog?.updateFeedAndRegistryOnAccountChange()
      
      self.visibleViewController?.navigationItem.title = AccountsManager.sharedInstance().currentAccount?.name
    }
  }
}
