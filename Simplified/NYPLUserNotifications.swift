import UserNotifications

let HoldNotificationCategoryIdentifier = "NYPLHoldToReserveNotificationCategory"
let HoldNotificationRequestIdentifier = "NYPLHoldNotificationRequest"
let CheckOutActionIdentifier = "NYPLCheckOutNotificationAction"
let DefaultActionIdentifier = "UNNotificationDefaultActionIdentifier"

@available (iOS 10.0, *)
@objcMembers class NYPLUserNotifications: NSObject {

  let unCenter = UNUserNotificationCenter.current()

  /// If a user has not yet been presented with Notifications authorization,
  /// defer the presentation for later to maximize acceptance rate. Otherwise,
  /// Apple documents authorization to be preformed at app-launch to corretly
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
      Log.info(#file, "Request Authorization Results: 'Granted': \(granted)." +
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
      if UIApplication.shared.applicationIconBadgeNumber != readyBooks {
        UIApplication.shared.applicationIconBadgeNumber = readyBooks
      }
    }
  }

  private class func createNotificationForReadyCheckout(book: NYPLBook)
  {
    let unCenter = UNUserNotificationCenter.current()
    unCenter.getNotificationSettings { (settings) in
      guard settings.authorizationStatus == .authorized else { return }

      let title = NSLocalizedString("Ready for Checkout", comment: "")
      let content = UNMutableNotificationContent()
      if let bookTitle = book.title {
        content.body = NSLocalizedString("Your loan, \(bookTitle), is now available for checkout!", comment: "")
      } else {
        content.body = NSLocalizedString("You have a loan available for checkout!", comment: "")
      }
      content.title = title
      content.sound = UNNotificationSound.default
      content.categoryIdentifier = HoldNotificationCategoryIdentifier
      content.userInfo = ["bookID" : book.identifier]

      let request = UNNotificationRequest.init(identifier: HoldNotificationRequestIdentifier,
                                               content: content,
                                               trigger: nil)
      unCenter.add(request)
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
extension NYPLUserNotifications: UNUserNotificationCenterDelegate {

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
      // User has tapped on the notification
      let currentAccount = AccountsManager.shared.currentAccount
      if currentAccount.supportsReservations {
        NYPLRootTabBarController.shared()?.selectedIndex = 2
      }
      completionHandler()
    } else if response.actionIdentifier == CheckOutActionIdentifier {
      // User has selected "Check Out" action.
      let userInfo = response.notification.request.content.userInfo
      guard let bookID = userInfo["bookID"] as? String else {
        Log.error(#file, "Bad user info in Local Notification.")
        return
      }
      guard let downloadCenter = NYPLMyBooksDownloadCenter.shared(),
        let book = NYPLBookRegistry.shared()?.book(forIdentifier: bookID) else {
          Log.error(#file, "Problem creating book or download center singleton.")
          return
      }
      downloadCenter.startBorrow(for: book, attemptDownload: false) {
        completionHandler()
      }
    }
  }
}
