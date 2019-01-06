import UserNotifications

let HoldNotificationCategoryIdentifier = "NYPLHoldToReserveNotificationCategory"
let HoldNotificationRequestIdentifier = "NYPLHoldNotificationRequest"
let CheckOutActionIdentifier = "NYPLCheckOutNotificationAction"

/// Handle Local Notifications
@objcMembers class NYPLHoldsNotifications: NSObject {

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

  @available(iOS 10.0, *)
  class func registerNotificationCategories() {

    //GODO TODO make a plan on where to put this...
    let checkOutNotificationAction = UNNotificationAction(identifier: CheckOutActionIdentifier,
                                                          title: NSLocalizedString("Check Out", comment: ""),
                                                          options: [])

    let holdToReserveCategory = UNNotificationCategory(identifier: HoldNotificationCategoryIdentifier,
                                                       actions: [checkOutNotificationAction],
                                                       intentIdentifiers: [],
                                                       options: [])

    UNUserNotificationCenter.current().setNotificationCategories([holdToReserveCategory])
  }

  class func requestAuthorization() {
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




/*
- (NSArray *)checkBookLoanStatusChange:(NSDictionary*)presyncDict WithPostSyncDict:(NSDictionary*)postSyncDict {
  NSMutableArray *booksWithChangedLoanStatus = [[NSMutableArray alloc] init];

  // For all objects in presyncDic that are waiting, check if that key (book identifier) is in postSyncDict
  // with object of type readyToCheckout. If so, add that book to array of books with changed loan status
  NSArray *waitingTitles = [presyncDict allKeysForObject:waitingForAvailability];

  for (NSString *identifier in waitingTitles) {
    // there's been a change, add to titles to send a notification later
    if (postSyncDict[identifier] == readyToCheckout) {
      NYPLBook *book = [self bookForIdentifier:identifier];
      [[NYPLBookRegistry sharedRegistry]
        setHoldsNotificationState:NYPLHoldsNotificationStateReadyForFirstNotification forIdentifier:identifier];
      NYPLLOG_F(@"This title has just become ready for checkout: %@", book.title);
      [booksWithChangedLoanStatus addObject:book];
    }
  }

  // For all objects that are still in readyToCheckout (from pre to post SyncDict),
  // see if a 1 day notification has already been sent. If not, check if there's only 1 day
  // left to checkout the book. If so, add that title to the bookTitles
  NSArray *readyTitles = [presyncDict allKeysForObject:readyToCheckout];

  for (NSString *identifier in readyTitles) {
    if (postSyncDict[identifier] == readyToCheckout) {
      NYPLBook *book = [self bookForIdentifier:identifier];
      if ([[NYPLBookRegistry sharedRegistry] holdsNotificationStateForIdentifier:book.identifier] ==
        NYPLHoldsNotificationStateFinalNotificationSent) {
        continue;
      }

      // Calculate the 24 hour period and set the NotificationState enum, if applicable
      NSDate * dateReservationExpires = book.defaultAcquisition.availability.until;
      if ([NSDate isTimeOneDayLeft:dateReservationExpires] == YES) {
        [[NYPLBookRegistry sharedRegistry]
          setHoldsNotificationState:NYPLHoldsNotificationStateReadyForFinalNotification forIdentifier:identifier];        NYPLLOG_F(@"This title has 24 hours or left to checkout: %@", book.title);
        [booksWithChangedLoanStatus addObject:book];
      }
    }
  }

  return booksWithChangedLoanStatus;
}
*/


