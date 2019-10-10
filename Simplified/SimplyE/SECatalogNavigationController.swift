class SECatalogNavigationController : NYPLCatalogNavigationController {
  override func loadTopLevelCatalogViewController() {
    super.loadTopLevelCatalogViewController()
    // The top-level view controller uses the same image used for the tab bar in place of the usual
    // title text.
    self.viewController.navigationItem.leftBarButtonItem = UIBarButtonItem.init(
      image: UIImage.init(named: "Catalog"),
      style: .plain,
      target: self,
      action: #selector(switchLibrary)
    )
    self.viewController.navigationItem.leftBarButtonItem?.accessibilityLabel = NSLocalizedString("AccessibilitySwitchLibrary", comment: "")
  }
  
  @objc func switchLibrary() {
    SEUtils.vcSwitchLibrary(context: self) { (account) in
      NYPLBookRegistry.shared()?.save()
      account.loadAuthenticationDocument(preferringCache: true) { (success) in
        DispatchQueue.main.async {
          if success {
            AccountsManager.shared.currentAccount = account
            self.updateFeedAndRegistryOnAccountChange()
          } else {
            self.present(UIAlertController.init(title: "", message: "LibraryLoadError", preferredStyle: .alert), animated: true)
          }
        }
      }
    }
  }
}
