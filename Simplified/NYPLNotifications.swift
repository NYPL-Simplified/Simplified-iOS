import UserNotifications

let HoldNotificationCategoryIdentifier = "NYPLHoldToReserveNotificationCategory"
let HoldNotificationRequestIdentifier = "NYPLHoldNotificationRequest"
let CheckOutActionIdentifier = "NYPLCheckOutNotificationAction"

@available(iOS 10.0, *)
fileprivate let unCenter = UNUserNotificationCenter.current()


@objcMembers class NYPLNotifications: NSObject {

  /// Create a local notification if a book has moved from the holds queue and is
  /// available to checkout.

  //GODO rename this function
  class func compareStatuses(cachedRecord:NYPLBookRegistryRecord, andNewBook newBook:NYPLBook) {
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
      createLocalNotification(book: newBook)
    }
  }


  //TODO GODO don't badge the icon inside notifications, badge it next to the existing badge logic for the toolbar

  private class func createLocalNotification(book: NYPLBook) {

    if #available(iOS 10.0, *) {
      let center = UNUserNotificationCenter.current()
      center.getNotificationSettings { (settings) in
        guard settings.authorizationStatus == .authorized else { return }

        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Ready for Checkout", comment: "")
        if let bookTitle = book.title {
          content.body = NSLocalizedString("Your loan, \(bookTitle), is now available for checkout!", comment: "")
        } else {
          content.body = NSLocalizedString("You have a loan available for checkout!", comment: "")
        }
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = HoldNotificationCategoryIdentifier

        let request = UNNotificationRequest.init(identifier: HoldNotificationRequestIdentifier,
                                                 content: content,
                                                 trigger: nil)
        center.add(request)
      }
    }
  }

  class func registerNotificationCategories() {
    if #available(iOS 10.0, *) {
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

  class func requestAuthorizationIfAvailable() {
    if #available(iOS 12.0, *) {
      let center = UNUserNotificationCenter.current()
      //GODO TODO i'm not convinced "provisional" is the UX we want. come back to this
      center.requestAuthorization(options: [.provisional,.badge,.sound,.alert]) { (granted, error) in
        if granted {
          Log.info(#file, "Full Notification Authorization granted.")
        }
      }
    } else if #available(iOS 10.0, *) {
      let center = UNUserNotificationCenter.current()
      center.requestAuthorization(options: [.badge,.sound,.alert]) { (granted, error) in
        if granted {
          Log.info(#file, "Full Notification Authorization granted.")
        }
      }
    }
  }
}
