class OEMyBooksNavigationController : NYPLMyBooksNavigationController {
  override init() {
    super.init()
    self.topViewController?.navigationItem.leftBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .refresh, target: self, action: #selector(didSelectSync))
    self.topViewController?.navigationItem.leftBarButtonItem?.accessibilityLabel = OEUtils.LocalizedString("AccessibilityRefresh")
    self.topViewController?.navigationItem.leftBarButtonItem?.isEnabled = true
  }
  
  @objc func didSelectSync() {
    if NYPLAccount.shared()?.hasCredentials() ?? false {
      NYPLBookRegistry.shared().syncWithStandardAlertsOnCompletion()
    } else {
      // We can't sync if we're not logged in, so let's log in. We don't need a completion handler
      // here because logging in will trigger a sync anyway. The only downside of letting the sync
      // happen elsewhere is that the user will not receive an error if the sync fails because it will
      // be considered an automatic sync and not a manual sync.
      // TODO: We should make this into a manual sync while somehow avoiding double-syncing.
      
      OETutorialChoiceViewController.showLoginPicker(handler: nil)
    }
  }
}
