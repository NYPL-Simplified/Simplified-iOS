class OECatalogNavigationController : NYPLCatalogNavigationController {
  override func loadTopLevelCatalogViewController() {
    super.loadTopLevelCatalogViewController()
    
    self.viewController.navigationItem.leftBarButtonItem = UIBarButtonItem.init(
      barButtonSystemItem: .refresh,
      target: self,
      action: #selector(reloadSelected)
    )
    self.viewController.navigationItem.leftBarButtonItem?.accessibilityLabel = OEUtils.LocalizedString("AccessibilityRefresh")
    self.viewController.navigationItem.leftBarButtonItem?.isEnabled = true
  }
  
  @objc func reloadSelected() {
    if self.visibleViewController is NYPLCatalogFeedViewController {
      let viewController = self.visibleViewController as! NYPLCatalogFeedViewController
      viewController.url = OEConfiguration.oeShared.mainFeedURL
      viewController.load()
    }
  }
}
