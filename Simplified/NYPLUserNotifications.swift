import UserNotifications

let HoldNotificationCategoryIdentifier = "NYPLHoldToReserveNotificationCategory"
let CheckOutActionIdentifier = "NYPLCheckOutNotificationAction"
let DefaultActionIdentifier = "UNNotificationDefaultActionIdentifier"

@available (iOS 10.0, *)
@objcMembers class NYPLUserNotifications: NSObject
{
  private let unCenter = UNUserNotificationCenter.current()

  /// If a user has not yet been presented with Notifications authorization,
  /// defer the presentation for later to maximize acceptance rate. Otherwise,
  /// Apple documents authorization to be preformed at app-launch to correctly
  /// enable the delegate.
  func authorizeIfNeeded()
  {
    unCenter.delegate = self
    unCenter.getNotificationSettings { (settings) in
      if settings.authorizationStatus == .notDetermined {
        Log.info(#file, "Deferring first-time UN Auth to a later time.")
      } else {
        self.registerNotificationCategories()
        NYPLUserNotifications.requestAuthorization()
      }
    }
  }

  class func requestAuthorization()
  {
    let unCenter = UNUserNotificationCenter.current()
    unCenter.requestAuthorization(options: [.badge,.sound,.alert]) { (granted, error) in
      Log.info(#file, "Notification Authorization Results: 'Granted': \(granted)." +
        " 'Error': \(error?.localizedDescription ?? "nil")")
    }
  }

  /// Create a local notification if a book has moved from the "holds queue" to
  /// the "reserved queue", and is available for the patron to checkout.
  class func compareAvailability(cachedRecord:NYPLBookRegistryRecord, andNewBook newBook:NYPLBook)
  {
    var wasOnHold = false
    var isNowReady = false
    let oldAvail = cachedRecord.book.defaultAcquisition()?.availability
    oldAvail?.matchUnavailable(nil,
                               limited: nil,
                               unlimited: nil,
                               reserved: { _ in wasOnHold = true },
                               ready: nil)
    let newAvail = newBook.defaultAcquisition()?.availability
    newAvail?.matchUnavailable(nil,
                               limited: nil,
                               unlimited: nil,
                               reserved: nil,
                               ready: { _ in isNowReady = true })

    if (wasOnHold && isNowReady) {
      createNotificationForReadyCheckout(book: newBook)
    }
  }

  class func updateAppIconBadge(heldBooks: [NYPLBook])
  {
    var readyBooks = 0
    for book in heldBooks {
      book.defaultAcquisition()?.availability.matchUnavailable(nil,
                                                               limited: nil,
                                                               unlimited: nil,
                                                               reserved: nil,
                                                               ready: { _ in readyBooks += 1 })
    }
    if UIApplication.shared.applicationIconBadgeNumber != readyBooks {
      UIApplication.shared.applicationIconBadgeNumber = readyBooks
    }
  }

  /// Depending on which Notificaitons are supported, only perform an expensive
  /// network operation if it's needed.
  class func backgroundFetchIsNeeded() -> Bool {
    Log.info(#file, "[backgroundFetchIsNeeded] Held Books: \(NYPLBookRegistry.shared().heldBooks.count)")
    return NYPLBookRegistry.shared().heldBooks.count > 0
  }

  private class func createNotificationForReadyCheckout(book: NYPLBook)
  {
    let unCenter = UNUserNotificationCenter.current()
    unCenter.getNotificationSettings { (settings) in
      guard settings.authorizationStatus == .authorized else { return }

      let title = NSLocalizedString("Ready for Download", comment: "")
      let content = UNMutableNotificationContent()
      content.body = NSLocalizedString("The title you reserved, \(book.title), is available.", comment: "")
      content.title = title
      content.sound = UNNotificationSound.default
      content.categoryIdentifier = HoldNotificationCategoryIdentifier
      content.userInfo = ["bookID" : book.identifier]

      let request = UNNotificationRequest.init(identifier: book.identifier,
                                               content: content,
                                               trigger: nil)
      unCenter.add(request) { error in
        if let error = error {
          NYPLErrorLogger.logError(error as NSError,
                                   summary: "Error creating notification for ready checkout",
                                   message: nil,
                                   metadata: [
                                    "book": book.loggableDictionary()])
        }
      }
    }
  }

  private func registerNotificationCategories()
  {
    let checkOutNotificationAction = UNNotificationAction(identifier: CheckOutActionIdentifier,
                                                          title: NSLocalizedString("Check Out", comment: ""),
                                                          options: [])
    let holdToReserveCategory = UNNotificationCategory(identifier: HoldNotificationCategoryIdentifier,
                                                       actions: [checkOutNotificationAction],
                                                       intentIdentifiers: [],
                                                       options: [])
    UNUserNotificationCenter.current().setNotificationCategories([holdToReserveCategory])
  }
}

@available (iOS 10.0, *)
extension NYPLUserNotifications: UNUserNotificationCenterDelegate
{
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
  {
    completionHandler([.alert])
  }

  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void)
  {
    if response.actionIdentifier == DefaultActionIdentifier {
      guard let currentAccount = AccountsManager.shared.currentAccount else {
        Log.error(#file, "Error moving to Holds tab from notification; there was no current account.")
        completionHandler()
        return
      }

      if currentAccount.details?.supportsReservations == true {
        if let holdsTab = NYPLRootTabBarController.shared()?.viewControllers?[2],
        holdsTab.isKind(of: NYPLHoldsNavigationController.self) {
          NYPLRootTabBarController.shared()?.selectedIndex = 2
        } else {
          Log.error(#file, "Error moving to Holds tab from notification.")
        }
      }
      completionHandler()
    }
    else if response.actionIdentifier == CheckOutActionIdentifier {
      Log.debug(#file, "'Check Out' Notification Action.")
      let userInfo = response.notification.request.content.userInfo
      
      guard let bookID = userInfo["bookID"] as? String else {
        Log.error(#file, "Bad user info in Local Notification. UserInfo: \n\(userInfo)")
        completionHandler()
        return
      }
      guard let downloadCenter = NYPLMyBooksDownloadCenter.shared() else {
          Log.error(#file, "Download center singleton is nil!")
          completionHandler()
          return
      }
      guard let book = NYPLBookRegistry.shared().book(forIdentifier: bookID) else {
          Log.error(#file, "Problem creating book. BookID: \(bookID)")
          completionHandler()
          return
      }

      borrow(book, inBackgroundFrom: downloadCenter, completion: completionHandler)
    }
    else {
      Log.warn(#file, "Unknown action identifier: \(response.actionIdentifier)")
      completionHandler()
    }
  }

  private func borrow(_ book: NYPLBook,
                      inBackgroundFrom downloadCenter: NYPLMyBooksDownloadCenter,
                      completion: @escaping () -> Void) {
    // Asynchronous network task in the background app state.
    var bgTask: UIBackgroundTaskIdentifier = .invalid
    bgTask = UIApplication.shared.beginBackgroundTask {
      if bgTask != .invalid {
        Log.warn(#file, "Expiring background borrow task \(bgTask.rawValue)")
        completion()
        UIApplication.shared.endBackgroundTask(bgTask)
        bgTask = .invalid
      }
    }

    Log.debug(#file, "Beginning background borrow task \(bgTask.rawValue)")

    if bgTask == .invalid {
      Log.debug(#file, "Unable to run borrow task in background")
    }

    // bg task body
    downloadCenter.startBorrow(for: book, attemptDownload: false) {
      completion()
      guard bgTask != .invalid else {
        return
      }
      Log.info(#file, "Finishing up background borrow task \(bgTask.rawValue)")
      UIApplication.shared.endBackgroundTask(bgTask)
      bgTask = .invalid
    }
  }
}
