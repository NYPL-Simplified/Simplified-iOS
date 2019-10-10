import Foundation

import NYPLAudiobookToolkit;

fileprivate let MinimumBackgroundFetchInterval = TimeInterval(60 * 60 * 24)

@objcMembers class NYPLAppDelegate: UIResponder {
  // Public members
  public var window: UIWindow?
  
  // Private members
  internal var audiobookLifecycleManager: AudiobookLifecycleManager
    
  // Initializer
  internal override init() {
    audiobookLifecycleManager = AudiobookLifecycleManager.init()
    super.init()
  }

  // MARK: UIApplicationDelegate
  
  func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    var bgTask = UIBackgroundTaskIdentifier.invalid
    bgTask = application.beginBackgroundTask(expirationHandler: {
      NYPLBugsnagLogs.reportExpiredBackgroundFetch()
      completionHandler(.failed)
      application.endBackgroundTask(bgTask)
    })
    
    Log.info("", "[BackgroundFetch] Starting background fetch block")
    if #available(iOS 10.0, *), NYPLUserNotifications.backgroundFetchIsNeeded() {
      // Only the "current library" account syncs during a background fetch.
      NYPLBookRegistry.shared()?.sync(completionHandler: { (success) in
        if (success) {
          NYPLBookRegistry.shared()?.save()
        }
      }, backgroundFetchHandler: { (result) in
        Log.info("BackgroundFetch", "Completed with result")
        completionHandler(result)
        application.endBackgroundTask(bgTask)
      })
    } else {
      Log.info("BackgroundFetch", "Fetch wasn't needed")
      completionHandler(.noData)
      application.endBackgroundTask(bgTask)
    }
  }
  
  @objc(application:openURL:options:) func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
     // URLs should be a permalink to a feed URL
    guard var components = URLComponents.init(url: url, resolvingAgainstBaseURL: false) else {
      reportErrorForOpenUrl(reason: "Could not parse url \(url.absoluteString)")
      return false
    }
    components.scheme = "http";
    guard let entryURL = components.url else {
      reportErrorForOpenUrl(reason: "Could not reform url \(url.absoluteString)")
      return false
    }
    guard let data = try? Data.init(contentsOf: entryURL) else {
      reportErrorForOpenUrl(reason: "Could not load data from \(entryURL.absoluteString)")
      return false
    }
    guard let xml = NYPLXML.init(data: data) else {
      reportErrorForOpenUrl(reason: "Could not parse data from \(entryURL.absoluteString)")
      return false
    }
    guard let entry = NYPLOPDSEntry.init(xml: xml) else {
      reportErrorForOpenUrl(reason: "Could not parse entry from \(entryURL.absoluteString)")
      return false
    }
    guard let book = NYPLBook.init(entry: entry) else {
      reportErrorForOpenUrl(reason: "Could not parse book from \(entryURL.absoluteString)")
      return false
    }
    guard let bookDetailVC = NYPLBookDetailViewController.init(book: book) else {
      reportErrorForOpenUrl(reason: "Could not instantiate bookDetailVC");
      return false
    }
    guard let tbc = self.window?.rootViewController as? NYPLRootTabBarController, tbc.selectedViewController is UINavigationController else {
      reportErrorForOpenUrl(reason: "Casted views were not of expected types.");
      return false
    }
    
    tbc.selectedIndex = 0
    let navFormSheet = tbc.selectedViewController?.presentedViewController as? UINavigationController
    
    if (tbc.traitCollection.horizontalSizeClass == .compact && tbc.selectedViewController is UINavigationController) {
      (tbc.selectedViewController as! UINavigationController).pushViewController(bookDetailVC, animated:true)
    } else if (navFormSheet != nil) {
      navFormSheet!.pushViewController(bookDetailVC, animated: true)
    } else {
      let navVC = UINavigationController.init(rootViewController: bookDetailVC)
      navVC.modalPresentationStyle = .formSheet
      tbc.selectedViewController?.present(navVC, animated: true, completion: nil)
    }
    return true;
  }
  
  func applicationWillResignActive(_ application: UIApplication) {
    NYPLBookRegistry.shared()?.save()
    NYPLReaderSettings.shared().save()
  }
  
  func applicationWillTerminate(_ application: UIApplication) {
    self.audiobookLifecycleManager.willTerminate()
    NYPLBookRegistry.shared()?.save()
    NYPLReaderSettings.shared().save()
  }
  
  func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
    self.audiobookLifecycleManager.handleEventsForBackgroundURLSession(for: identifier, completionHandler: completionHandler)
  }

  // MARK: -
  
  func reportErrorForOpenUrl(reason: String) {
    Log.warn("[application:openUrl]", reason)
  }
  
  @objc func beginCheckingForUpdates() {
    UpdateCheckShim.performUpdateCheckWithURL(NYPLConfiguration.shared.minimumVersionURL!) { (version, updateUrl) in
      OperationQueue.main.addOperation {
        let alertController = UIAlertController.init(title: NSLocalizedString("AppDelegateUpdateRequiredTitle", comment: ""),
                                                     message: String(format: NSLocalizedString("AppDelegateUpdateRequiredMessageFormat", comment: ""), [version]),
                                                     preferredStyle: .alert)
        alertController.addAction(UIAlertAction.init(title: NSLocalizedString("AppDelegateUpdateNow", comment: ""),
                                                     style: .default,
                                                     handler: { (action) in
                                                      UIApplication.shared.openURL(updateUrl)
        }))
        alertController.addAction(UIAlertAction.init(title: NSLocalizedString("AppDelegateUpdateRemindMeLater", comment: ""),
                                                     style: .cancel,
                                                     handler: nil
        ))
        self.window?.rootViewController?.present(alertController, animated: true, completion: {
          // Try again in 24 hours or on next launch, whichever is sooner.
          self.perform(#selector(self.beginCheckingForUpdates), with: nil, afterDelay: 60.0 * 60.0 * 24.0)
        })
      }
    }
  }
}
