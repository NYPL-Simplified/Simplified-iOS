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

  // create the notification and then add it to the
  // notification center
  func sendNotification(book: NYPLBook?) {
    // create the Trigger
    let seconds = 3
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)

    // create Notification content
    let content = UNMutableNotificationContent()

    // adding title, subtitle, body and badge
    content.title = "Book Ready to Check Out"
    content.subtitle = book?.title ?? "No book title available"
    content.body = "You'll Have the Option to Check Out Book from Here Later"
    content.badge = 1

    // getting the notification request
    let request = UNNotificationRequest(identifier: "SimplyEIOSNotification_" + Date().description, content: content, trigger: trigger)

    UNUserNotificationCenter.current().delegate = self

    // adding the notification to notification center
    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
  }



  func requestAuthorization() {
    center.requestAuthorization(options: [.alert, .sound, .badge], completionHandler: { [weak self] (granted, error) in
      guard self != nil else { return }

      if granted {

      }

    })

  }

  override init() {

  }

  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

    //displaying the ios local notification when app is in foreground
    completionHandler([.alert, .badge, .sound])
  }

}
