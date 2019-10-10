import HelpStack

fileprivate let MinimumBackgroundFetchInterval = TimeInterval(60 * 60 * 24)

@UIApplicationMain
class OEAppDelegate : NYPLAppDelegate, UIApplicationDelegate {
  override init() {
    super.init()
  }

  // MARK: UIApplicationDelegate

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    // Swap superclass shared value with subclass
    NYPLConfiguration.shared = OEConfiguration.oeShared
    AccountsManager.shared.delayedInit()
    OEMigrationManager.migrate()
    
    self.audiobookLifecycleManager.didFinishLaunching()

    UIApplication.shared.setMinimumBackgroundFetchInterval(MinimumBackgroundFetchInterval)

    if #available(iOS 10.0, *) {
      NYPLUserNotifications.init().authorizeIfNeeded()
    }

    // This is normally not called directly, but we put all programmatic appearance setup in
    // NYPLConfiguration's class initializer.
    OEConfiguration.initConfig()

    NetworkQueue.shared().addObserverForOfflineQueue()

    self.window = UIWindow.init(frame: UIScreen.main.bounds)
    self.window!.tintColor = NYPLConfiguration.shared.mainColor
    self.window!.tintAdjustmentMode = .normal
    self.window!.makeKeyAndVisible()
    
    NYPLRootTabBarController.shared()?.setCatalogNav(OECatalogNavigationController())
    NYPLRootTabBarController.shared()?.setMyBooksNav(OEMyBooksNavigationController())
    NYPLRootTabBarController.shared()?.setHoldsNav(OEHoldsNavigationController())
    configSettingsTab()
    
    if OESettings.oeShared.userHasAcceptedEULA {
      if NYPLSettings.shared.userHasSeenWelcomeScreen {
        self.window!.rootViewController = NYPLRootTabBarController.shared()
      } else {
        self.window!.rootViewController = OETutorialViewController()
      }
    } else {
      let eulaVC = OEEULAViewController() {
        UIView.transition(
          with: self.window!,
          duration: 0.5,
          options: [.transitionCurlUp, .allowAnimatedContent, .layoutSubviews],
          animations: {
            self.window?.rootViewController = OETutorialViewController()
          },
          completion: nil
        )
      }
      let eulaNavController = UINavigationController.init(rootViewController: eulaVC)
      self.window?.rootViewController = eulaNavController
    }
    
    self.beginCheckingForUpdates()

    return true;
  }
  
  func configSettingsTab() {
    guard let splitVC = NYPLRootTabBarController.shared()?.viewControllers?.last as? NYPLSettingsSplitViewController else {
      Log.error("SEAppDelegate", "Cannot locate settingsSplitViewController")
      return
    }
    splitVC.primaryTableVC?.items = [
      NYPLSettingsPrimaryTableItem.init(
        indexPath: IndexPath.init(row: 0, section: 0),
        title: "Account",
        selectionHandler: { (splitVC, tableVC) in
          if NYPLAccount.shared()?.hasCredentials() ?? false {
            splitVC.show(
              NYPLSettingsPrimaryTableItem.handleVCWrap(
                NYPLSettingsAccountDetailViewController(
                  account: AccountsManager.shared.currentAccountId
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
        indexPath: IndexPath.init(row: 0, section: 1),
        title: "Help",
        selectionHandler: { (splitVC, tableVC) in
          let hs = HSHelpStack.instance() as! HSHelpStack
          hs.showHelp(splitVC)
        }
      ),
      NYPLSettingsPrimaryTableItem.init(
        indexPath: IndexPath.init(row: 0, section: 2),
        title: "Acknowledgements",
        viewController: NYPLSettingsPrimaryTableItem.generateRemoteView(
          title: "Acknowledgements",
          url: "http://www.librarysimplified.org/openebooksacknowledgments.html"
        )
      ),
      NYPLSettingsPrimaryTableItem.init(
        indexPath: IndexPath.init(row: 1, section: 2),
        title: "User Agreement",
        viewController: NYPLSettingsPrimaryTableItem.generateRemoteView(
          title: "User Agreement",
          url: "http://www.librarysimplified.org/openebookseula.html"
        )
      ),
      NYPLSettingsPrimaryTableItem.init(
        indexPath: IndexPath.init(row: 2, section: 2),
        title: "Privacy Policy",
        viewController: NYPLSettingsPrimaryTableItem.generateRemoteView(
          title: "Privacy Policy",
          url: "http://www.librarysimplified.org/oeiprivacy.html"
        )
      )
    ]
  }
  
  @objc(application:openURL:options:) override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    if url.scheme == "open-ebooks-clever" {
      NotificationCenter.default.post(name: .OEAppDelegateDidReceiveCleverRedirectURL, object: url)
      return true
    }
    
    return super.application(app, open: url, options: options)
  }
}
