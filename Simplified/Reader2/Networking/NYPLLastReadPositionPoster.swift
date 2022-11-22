//
//  NYPLLastReadPositionPoster.swift
//  Simplified
//
//  Created by Ettore Pasquini on 3/9/21.
//  Copyright © 2021 NYPL. All rights reserved.
//

import Foundation
import R2Shared

/// A front-end to the Annotations api to post a new reading progress for
/// a given book.
class NYPLLastReadPositionPoster {
  /// Interval used to throttle request submission.
  static let throttlingInterval = 5.0

  // models
  private let book: NYPLBook

  // external dependencies
  private let bookRegistryProvider: NYPLBookRegistryProvider
  private let synchronizer: NYPLLastReadPositionSupportAPI

  // internal state management
  private var lastReadPositionUploadDate: Date
  private var queuedReadPosition: String = ""
  private let serialQueue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier!).lastReadPositionPoster", target: .global(qos: .utility))

  init(book: NYPLBook,
       bookRegistryProvider: NYPLBookRegistryProvider,
       synchronizer: NYPLLastReadPositionSupportAPI) {
    self.book = book
    self.bookRegistryProvider = bookRegistryProvider
    self.lastReadPositionUploadDate = Date()
      .addingTimeInterval(-NYPLLastReadPositionPoster.throttlingInterval)
    self.synchronizer = synchronizer

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
    guard (locator.locations.totalProgression ?? 0) != 0 else {
      return
    }

    guard let chapterProgress = locator.locations.progression else {
      return
    }

    guard let location = NYPLBookLocation(locator: locator) else {
      return
    }

    // save location locally, so that it can be saved on disk later
    bookRegistryProvider.setLocation(location, forIdentifier: book.identifier)

    // attempt to store location on server
    if synchronizer.syncIsPossibleAndPermitted() {
      let selectorValue = NYPLReadiumBookmarkFactory
        .makeLocatorString(chapterHref: locator.href,
                           chapterProgression: Float(chapterProgress))

      postReadPosition(selectorValue: selectorValue)
    }
  }

  // MARK:- Private helpers
  
  /// Post the read position to server.
  ///
  /// Requests are throttled by a `throttlingInterval` to avoid an unreasonably
  /// high frequency of updates.
  ///
  /// - Parameter selectorValue: A JSON string that includes a serialized
  /// [locator](https://git.io/JYTyx) that uniquely identifies a position
  /// within the book.
  private func postReadPosition(selectorValue: String) {
    serialQueue.async { [weak self] in
      guard let self = self else { return }

      // save location string anyway so that if the app becomes inactive
      // we still have a chance to post it.
      self.queuedReadPosition = selectorValue

      if Date() > self.lastReadPositionUploadDate.addingTimeInterval(NYPLLastReadPositionPoster.throttlingInterval) {
        self.postQueuedReadPosition()
      }
    }
  }

  @objc private func postQueuedReadPositionInSerialQueue() {
    if synchronizer.syncIsPossibleAndPermitted() {
      serialQueue.async { [weak self] in
        self?.postQueuedReadPosition()
      }
    }
  }

  /// Wrapper for actual api call.
  private func postQueuedReadPosition() {
    guard self.queuedReadPosition != "" else {
      return
    }

    synchronizer.postReadingPosition(forBook: book.identifier,
                                                selectorValue: queuedReadPosition)
    self.queuedReadPosition = ""
    self.lastReadPositionUploadDate = Date()
  }
}
