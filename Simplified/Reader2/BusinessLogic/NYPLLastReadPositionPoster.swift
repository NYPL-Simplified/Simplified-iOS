//
//  NYPLLastReadPositionPoster.swift
//  Simplified
//
//  Created by Ettore Pasquini on 3/9/21.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
import R2Shared

/// A front-end to the Annotations api to post a new reading progress for
/// a given book.
class NYPLLastReadPositionPoster {
  /// Interval used to throttle request submission.
  static let throttlingInterval = 30.0

  // models
  private let publication: Publication
  private let book: NYPLBook

  // external dependencies
  private let bookRegistryProvider: NYPLBookRegistryProvider

  // internal state management
  private var lastReadPositionUploadDate: Date
  private var queuedReadPosition: String = ""
  private let serialQueue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier!).lastReadPositionPoster", target: .global(qos: .utility))

  init(book: NYPLBook,
       r2Publication: Publication,
       bookRegistryProvider: NYPLBookRegistryProvider) {
    self.book = book
    self.publication = r2Publication
    self.bookRegistryProvider = bookRegistryProvider
    self.lastReadPositionUploadDate = Date()
      .addingTimeInterval(-NYPLLastReadPositionPoster.throttlingInterval)

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(postQueuedReadPositionInSerialQueue),
                                           name: UIApplication.willResignActiveNotification,
                                           object: nil)
  }

  // MARK:- Storing

  /// Stores a new reading progress location on the server.
  /// - Parameter locator: The new local progress to be stored.
  func storeReadPosition(locator: Locator) {
    // Avoid overwriting location when reader first open
    guard (locator.locations.totalProgression ?? 0) != 0,
      let bookLocation = NYPLBookLocation(locator: locator, publication: publication) else {
        return
    }

    bookRegistryProvider.setLocation(bookLocation, forIdentifier: book.identifier)
    postReadPosition(locationString: bookLocation.locationString)
  }

  /// Post the read position to server.
  ///
  /// Requests are throttled by a `throttlingInterval` to avoid an unreasonably
  /// high frequency of updates.
  ///
  /// - Parameters:
  /// - locationString: A JSON string (CFI) that contains the required
  /// information to create a Locator object.
  private func postReadPosition(locationString: String) {
    serialQueue.async { [weak self] in
      guard let self = self else { return }

      // save location string anyway so that if the app becomes inactive
      // we still have a chance to post it.
      self.queuedReadPosition = locationString

      if Date() > self.lastReadPositionUploadDate.addingTimeInterval(NYPLLastReadPositionPoster.throttlingInterval) {
        self.postQueuedReadPosition()
      }
    }
  }

  private func postQueuedReadPosition() {
    if self.queuedReadPosition != "" {
      NYPLAnnotations.postReadingPosition(forBook: book.identifier,
                                          annotationsURL: nil,
                                          cfi: self.queuedReadPosition)
      self.queuedReadPosition = ""
      self.lastReadPositionUploadDate = Date()
    }
  }

  @objc private func postQueuedReadPositionInSerialQueue() {
    serialQueue.async { [weak self] in
      self?.postQueuedReadPosition()
    }
  }
}