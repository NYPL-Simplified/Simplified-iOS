//
//  NYPLHoldsNotifications.swift
//  SimplyE
//
//  Created by Vui Nguyen on 10/19/18.
//  Copyright © 2018 NYPL Labs. All rights reserved.
//

import UserNotifications

@available(iOS 10.0, *)
@objcMembers class NYPLHoldsNotifications: NSObject, UNUserNotificationCenterDelegate {

  private let center = UNUserNotificationCenter.current()

  static let sharedInstance = NYPLHoldsNotifications()

  // create the notification and then add it to the
  // notification center
  // we need to go back to using NYPLBook because now we need state (from BookRegistryRecord)
  // and title, from book
  func sendNotification(books: [NYPLBook]) {
    if books.count == 0 { return }
    //sendNotification(bookTitles: books.map {$0.title})

    // create the Trigger
    let seconds = 3
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)

    // create Notification content
    let content = UNMutableNotificationContent()

    var titlesString = ("Books available for checkout are: ")
    for book in books {
      if let title = book.title {
        titlesString = titlesString + title + " , "
      }
    }
    print(titlesString)

    // this for loop is to change the notification sent status for each book
    var readyForFinalNotificationStateExists = false
    for book in books {
      if NYPLBookRegistry.shared()?.holdsNotificationState(forIdentifier: book.identifier) ==
        NYPLHoldsNotificationState.readyForFinalNotification {
        readyForFinalNotificationStateExists = true
        NYPLBookRegistry.shared()?.setHoldsNotificationState(NYPLHoldsNotificationState.finalNotificationSent, forIdentifier: book.identifier)
      } else if NYPLBookRegistry.shared()?.holdsNotificationState(forIdentifier: book.identifier) ==
        NYPLHoldsNotificationState.readyForFirstNotification {
        NYPLBookRegistry.shared()?.setHoldsNotificationState(NYPLHoldsNotificationState.firstNotificationSent, forIdentifier: book.identifier)
      }
    }

    // if you have 1 book with more than 24 hours, send message for first notification
    // if you have 1 book with 24 hours left, send message for 24 hours

    // if there are multiple books and none of them is 24 hours, send message for 1st notification for multiple books
    // if there are multiple books, and 1 or more of them is 24 hours, you have 24 hours to check out book(s)
    if books.count == 1 {
      content.title = readyForFinalNotificationStateExists ?
                      NSLocalizedString("NYPLHoldsNotificationsOneDayToCheckoutABook", comment: "Notification telling patron they have only a day left to checkout a book on hold"):
                      NSLocalizedString("NYPLHoldsNotificationsABookReadyToCheckout", comment: "Notification telling patron that a book they had on hold is now ready to checkout")

      if let bookTitle = books[0].title {
        content.body = bookTitle
      }
    } else if books.count > 1 {
      content.title = readyForFinalNotificationStateExists ?
                      NSLocalizedString("NYPLHoldsNotificationsOneDayToCheckoutBooks", comment: "Notification telling patron they have only one day left checkout one or more books on hold"):
                      NSLocalizedString("NYPLHoldsNotificationsBooksReadyToCheckout", comment: "Notification telling patron that multiple books they had on hold are now ready to checkout")
    }
    content.badge = 1

    // getting the notification request
    let request = UNNotificationRequest(identifier: "SimplyEIOSNotification_" + Date().description, content: content, trigger: trigger)

    UNUserNotificationCenter.current().delegate = self

    // adding the notification to notification center
    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
  }

  /*
  func sendNotification(bookTitles: [String]) {
    if bookTitles.count == 0 { return }
    // create the Trigger
    let seconds = 3
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)

    // create Notification content
    let content = UNMutableNotificationContent()

    var titlesString = ("Books available for checkout are: ")
    for title in bookTitles {
      titlesString = titlesString + title + " , "
    }
    print(titlesString)

    if bookTitles.count == 1 {
      content.title = NSLocalizedString("NYPLHoldsNotificationsABookReadyToCheckout",
                                        comment: "Notification telling patron that a book they had on hold is now ready to checkout")
      content.body = bookTitles[0]
    } else if bookTitles.count > 1 {
      content.title = NSLocalizedString("NYPLHoldsNotificationsBooksReadyToCheckout",
                                        comment: "Notification telling patron that multiple books they had on hold are now ready to checkout")
    }
    content.badge = 1

    // getting the notification request
    let request = UNNotificationRequest(identifier: "SimplyEIOSNotification_" + Date().description, content: content, trigger: trigger)

    UNUserNotificationCenter.current().delegate = self

    // adding the notification to notification center
    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
  }
 */

  func requestAuthorization() {
    // with provisional authorization, patrons don't have to be prompted to allow notifications,
    // the notifications can still be sent to the Notification Center
    if #available(iOS 12.0, *) {
      center.requestAuthorization(options: [.alert, .sound, .badge, .provisional], completionHandler: { [weak self] (granted, error) in
        guard self != nil else { return }

        if granted {

        }

      })
    } else {
      // Fallback on earlier versions
      center.requestAuthorization(options: [.alert, .sound, .badge], completionHandler: { [weak self] (granted, error) in
        guard self != nil else { return }

        if granted {

        }

      })
    }

  }

  override init() {

  }

  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

    //displaying the ios local notification when app is in foreground
    completionHandler([.alert, .badge, .sound])
  }

}
