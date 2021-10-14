//
//  NYPLMyBooksNotifier.swift
//  Simplified
//
//  Created by Ettore Pasquini on 10/13/21.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import UIKit

class NYPLMyBooksNotifier: NSObject {
  @objc
  static func announceSuccessfulBookReturn(_ book: NYPLBook) {
    let announcement = String.localizedStringWithFormat(
      NSLocalizedString("%@ was returned successfully.",
                        comment: "Accessibility announcement for returning a book"),
      book.title)
    UIAccessibility.post(notification: .announcement,
                         argument: announcement)
  }
}
