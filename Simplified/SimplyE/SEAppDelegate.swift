fileprivate let MinimumBackgroundFetchInterval = TimeInterval(60 * 60 * 24)

@UIApplicationMain
class SEAppDelegate : NYPLAppDelegate, UIApplicationDelegate {
  override init() {
    super.init()
  }

  // MARK: UIApplicationDelegate

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    // Swap superclass shared value with subclass
    NYPLConfiguration.shared = SEConfiguration.seShared
    
    // Perform data migrations as early as possible before anything has a chance to access them
    NYPLKeychainManager.validateKeychain()
    
    SEMigrationManager.migrate()
    
    AccountsManager.shared.delayedInit()
    
    self.audiobookLifecycleManager.didFinishLaunching()

    UIApplication.shared.setMinimumBackgroundFetchInterval(MinimumBackgroundFetchInterval)

    if #available(iOS 10.0, *) {
      NYPLUserNotifications.init().authorizeIfNeeded()
    }

    // This is normally not called directly, but we put all programmatic appearance setup in
    // NYPLConfiguration's class initializer.
    NYPLConfiguration.initConfig()

    NetworkQueue.shared().addObserverForOfflineQueue()

    self.window = UIWindow.init(frame: UIScreen.main.bounds)
    self.window!.tintColor = NYPLConfiguration.shared.mainColor
    self.window!.tintAdjustmentMode = .normal
    self.window!.makeKeyAndVisible()
    
    NYPLRootTabBarController.shared()?.setCatalogNav(SECatalogNavigationController())
    NYPLRootTabBarController.shared()?.setMyBooksNav(SEMyBooksNavigationController())
    NYPLRootTabBarController.shared()?.setHoldsNav(SEHoldsNavigationController())
    configSettingsTab()
    
    if NYPLSettings.shared.userHasSeenWelcomeScreen {
      self.window!.rootViewController = NYPLRootTabBarController.shared()
    } else {
      self.window!.rootViewController = SETutorialViewController()
    }
    
    self.beginCheckingForUpdates()

    return true;
  }
  
  fileprivate func configSettingsTab() {
    guard let splitVC = NYPLRootTabBarController.shared()?.viewControllers?.last as? NYPLSettingsSplitViewController else {
      Log.error("SEAppDelegate", "Cannot locate settingsSplitViewController")
      return
    }
    splitVC.primaryTableVC?.items = [
      NYPLSettingsPrimaryTableItem.init(
        indexPath: IndexPath.init(row: 0, section: 0),
        title: NSLocalizedString("Accounts", comment: ""),
        viewController: NYPLSettingsPrimaryTableItem.handleVCWrap(
          NYPLSettingsAccountsTableViewController.init(
            accounts: NYPLSettings.shared.settingsAccountsList
          )
        )
      ),
      NYPLSettingsPrimaryTableItem.init(
        indexPath: IndexPath.init(row: 0, section: 1),
        title: NSLocalizedString("AboutApp", comment: ""),
        viewController: NYPLSettingsPrimaryTableItem.generateRemoteView(
          title: NSLocalizedString("AboutApp", comment: ""),
          url: NYPLSettings.NYPLAcknowledgementsURLString
        )
      ),
      NYPLSettingsPrimaryTableItem.init(
        indexPath: IndexPath.init(row: 1, section: 1),
        title: NSLocalizedString("EULA", comment: ""),
        viewController: NYPLSettingsPrimaryTableItem.generateRemoteView(
          title: NSLocalizedString("EULA", comment: ""),
          url: NYPLSettings.NYPLUserAgreementURLString
        )
      ),
      NYPLSettingsPrimaryTableItem.init(
        indexPath: IndexPath.init(row: 2, section: 1),
        title: NSLocalizedString("SoftwareLicenses", comment: ""),
        viewController: NYPLSettingsPrimaryTableItem.handleVCWrap(
          BundledHTMLViewController.init(
            fileURL: Bundle.init(for: NYPLSettings.self).url(
              forResource: "software-licenses",
              withExtension: "html"
            )!,
            title: NSLocalizedString("SoftwareLicenses", comment: "")
          )
        )
      )
    ]
  }
}
