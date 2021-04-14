//
//  NYPLBookmarkFactory.swift
//  Simplified
//
//  Created by Ettore Pasquini on 3/22/21.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
import R2Shared

class NYPLBookmarkFactory {

  private let publication: Publication?
  private let drmDeviceID: String?

  init(publication: Publication?, drmDeviceID: String?) {
    self.publication = publication
    self.drmDeviceID = drmDeviceID
  }

  // MARK:- Bookmarks creation

  func make(fromR2Location bookmarkLoc: NYPLBookmarkR2Location) -> NYPLReadiumBookmark? {
    guard let progression = bookmarkLoc.locator.locations.progression else {
      return nil
    }
    let chapterProgress = Float(progression)

    let href = bookmarkLoc.locator.href

    let progressWithinBook: NSNumber?
    if let totalProgression = bookmarkLoc.locator.locations.totalProgression {
      progressWithinBook = NSNumber(value: totalProgression)
    } else {
      progressWithinBook = nil
    }

    let page: String?
    if let position = bookmarkLoc.locator.locations.position {
      page = "\(position)"
    } else {
      page = nil
    }

    let chapter: String?
    if let locatorChapter = bookmarkLoc.locator.title {
      chapter = locatorChapter
    } else if let tocLink = publication?.tableOfContents.first(withHREF: bookmarkLoc.locator.href) {
      chapter = tocLink.title
    } else {
      chapter = nil
    }

    return NYPLReadiumBookmark(
      annotationId: nil,
      contentCFI: nil,
      href: href,
      idref: nil,
      chapter: chapter,
      page: page,
      location: nil,
      progressWithinChapter: chapterProgress,
      progressWithinBook: progressWithinBook,
      creationTime: bookmarkLoc.creationDate,
      device: drmDeviceID)
  }

  /// Factory method to create a new bookmark from a server annotation.
  ///
  /// - Parameters:
  ///   - annotation: The annotation object coming from the server in a
  ///   JSON-like structure.
  ///   - annotationType: Whether it's an explicit bookmark or a reading progress.
  ///   - bookID: The book the annotation is related to.
  ///   - publication: R2 object only used to derive the `href` if that's
  ///   missing from the annotation, e.g. if the annotation was created on an
  ///   R1 client.
  /// - Returns: a client-side representation of a bookmark.
  class func make(fromServerAnnotation annotation: [String: Any],
                  annotationType: NYPLBookmarkSpec.Motivation,
                  bookID: String,
                  publication: Publication? = nil) -> NYPLReadiumBookmark? {

    guard let annotationID = annotation[NYPLBookmarkSpec.Id.key] as? String else {
      Log.error(#file, "Missing AnnotationID:\(annotation)")
      return nil
    }

    guard let target = annotation[NYPLBookmarkSpec.Target.key] as? [String: Any],
      let source = target[NYPLBookmarkSpec.Target.Source.key] as? String,
      let motivation = annotation[NYPLBookmarkSpec.Motivation.key] as? String,
      let body = annotation[NYPLBookmarkSpec.Body.key] as? [String: Any]
    else {
      Log.error(#file, "Error parsing required info (target, source, motivation, body) in annotation: \(annotation)")
      return nil
    }

    guard source == bookID else {
      NYPLErrorLogger.logError(withCode: .bookmarkReadError,
                               summary: "Got bookmark for a different book",
                               metadata: [
                                "requestedBookID": bookID,
                                "serverAnnotation": annotation])
      return nil
    }

    guard motivation.contains(annotationType.rawValue) else {
      Log.error(#file, "Can't create bookmark, `\(motivation)` motivation does not match expected `\(annotationType.rawValue)` motivation.")
      return nil
    }

    guard let device = body[NYPLBookmarkSpec.Body.Device.key] as? String else {
      Log.error(#file, "Error reading `device` info from `body`:\(body)")
      return nil
    }

    guard
      let selector = target[NYPLBookmarkSpec.Target.Selector.key] as? [String: Any],
      let selectorValueEscJSON = selector[NYPLBookmarkSpec.Target.Selector.Value.key] as? String
      else {
        Log.error(#file, "Error reading required Selector Value from Target: \(target)")
        return nil
    }

    guard let (href, idref, progress) =
      parseLocatorString(selectorValueEscJSON, publication: publication) else {
        return nil
    }

    // if we can't derive the href, we cannot use this bookmark in R2
    guard href != nil else {
      Log.error(#file, "Error reading chapter ID from server annotation. SelectorValue=\(selectorValueEscJSON)")
      return nil
    }

    let legacyProgress = body["http://librarysimplified.org/terms/progressWithinChapter"]
    let progressWithinChapter = (progress ?? legacyProgress as? Double) ?? 0.0
    let creationTime = NYPLBookmarkFactory.makeCreationTime(fromRFC3339timestamp:
      body[NYPLBookmarkSpec.Body.Time.key] as? String)

    // non-essential info
    let chapter = body["http://librarysimplified.org/terms/chapter"] as? String
    let progressWithinBook: NSNumber?
    if let bookProgress = body[NYPLBookmarkSpec.Body.BookProgress.key] as? Double {
      progressWithinBook = NSNumber(value: bookProgress)
    } else {
      progressWithinBook = nil
    }

    return NYPLReadiumBookmark(annotationId: annotationID,
                               contentCFI: nil,
                               href: href,
                               idref: idref,
                               chapter: chapter,
                               page: nil,
                               location: nil,
                               progressWithinChapter: Float(progressWithinChapter),
                               progressWithinBook: progressWithinBook,
                               creationTime: creationTime,
                               device:device)
  }

  // MARK:- Locators / Selector Values

  class func parseLocatorString(
    _ selectorValueEscJSON: String,
    publication: Publication?) -> (href: String?, idref: String?, progression: Double?)? {

    guard let (selectorHref, idref, progress) = parseLocatorString(selectorValueEscJSON) else {
      return nil
    }

    var href = selectorHref
    if selectorHref == nil && idref != nil {
      href = publication?.href(forIdref: idref)
    }

    return (href, idref, progress)
  }

  class func parseLocatorString(
    _ selectorValueEscJSON: String) -> (href: String?, idref: String?, progression: Double?)? {

    guard
      let selectorValueData = selectorValueEscJSON.data(using: String.Encoding.utf8),
      let selectorValueJSON = (try? JSONSerialization.jsonObject(with: selectorValueData)) as? [String: Any]
      else {
        Log.error(#file, "Error serializing locator. SelectorValue=\(selectorValueEscJSON)")
        return nil
    }

    // either the `href` or `idref` may be nil: e.g. if we retrieved a bookmark
    // saved by R1, `href` will be nil, and viceversa for R2. However, they
    // should not be nil at the same time
    let href = selectorValueJSON[NYPLBookmarkSpec.Target.Selector.Value.locatorChapterIDKey] as? String
    let idref = selectorValueJSON[NYPLBookmarkR1Key.idref.rawValue] as? String
    let progress = selectorValueJSON[NYPLBookmarkSpec.Target.Selector.Value.locatorChapterProgressionKey] as? Double

    return (href: href, idref: idref, progression: progress)
  }

  class func makeLocatorString(chapterHref: String, chapterProgression: Float) -> String {
    var progression = chapterProgression
    if chapterProgression < 0.0 {
      progression = 0.0
    } else if chapterProgression > 1.0 {
      progression = 1.0
    }

    return """
    {
      "\(NYPLBookmarkSpec.Target.Selector.Value.locatorTypeKey)": "\(NYPLBookmarkSpec.Target.Selector.Value.locatorTypeValue)",
      "\(NYPLBookmarkSpec.Target.Selector.Value.locatorChapterIDKey)": "\(chapterHref)",
      "\(NYPLBookmarkSpec.Target.Selector.Value.locatorChapterProgressionKey)": \(progression)
    }
    """
  }

  class func makeLegacyLocatorString(idref: String,
                                     chapterProgression: Float,
                                     cfi: String) -> String {
    return """
    {
      "\(NYPLBookmarkSpec.Target.Selector.Value.locatorTypeKey)": "\(NYPLBookmarkSpec.Target.Selector.Value.legacyLocatorTypeValue)",
      "\(NYPLBookmarkR1Key.idref.rawValue)": "\(idref)",
      "\(NYPLBookmarkSpec.Target.Selector.Value.legacyLocatorCFIKey)": "\(cfi)",
      "\(NYPLBookmarkSpec.Target.Selector.Value.locatorChapterProgressionKey)": \(chapterProgression)
    }
    """
  }

  // MARK:- Helpers

  class func makeCreationTime(fromRFC3339timestamp time: String?) -> Date {
    if let rfc3339time = time, let date = NSDate(rfc3339String: rfc3339time) {
      return date as Date
    } else {
      return Date()
    }
  }
}
