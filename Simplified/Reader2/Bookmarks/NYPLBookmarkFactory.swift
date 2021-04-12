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

  private let book: NYPLBook
  private let publication: Publication
  private let drmDeviceID: String?

  init(book: NYPLBook, publication: Publication, drmDeviceID: String?) {
    self.book = book
    self.publication = publication
    self.drmDeviceID = drmDeviceID
  }

  // MARK:- Bookmarks creation

  func make(fromR2Location bookmarkLoc: NYPLBookmarkR2Location,
            usingBookRegistry bookRegistry: NYPLBookRegistryProvider) -> NYPLReadiumBookmark? {

    guard let progression = bookmarkLoc.locator.locations.progression else {
      return nil
    }
    let chapterProgress = Float(progression)

    guard let total = bookmarkLoc.locator.locations.totalProgression else {
      return nil
    }
    let totalProgress = Float(total)

    var page: String? = nil
    if let position = bookmarkLoc.locator.locations.position {
      page = "\(position)"
    }

    let registryLoc = bookRegistry.location(forIdentifier: book.identifier)
    var cfi: String? = nil
    var idref: String? = nil
    if registryLoc?.locationString != nil,
      let data = registryLoc?.locationString.data(using: .utf8),
      let registryLocationJSON = try? JSONSerialization.jsonObject(with: data),
      let registryLocationDict = registryLocationJSON as? [String: Any] {

      cfi = registryLocationDict[NYPLBookmarkSpec.Target.Selector.Value.legacyLocatorCFIKey] as? String

      // backup idref from R1 in case parsing from R2 fails for some reason
      idref = registryLocationDict[NYPLBookmarkR1Key.idref.rawValue] as? String
    }

    // get the idref from R2 data structures. Should be more reliable than R1's
    // when working with R2 since it comes directly from a R2 Locator object.
    if let idrefFromR2 = publication.idref(forHref: bookmarkLoc.locator.href) {
      idref = idrefFromR2
    }

    let chapter: String?
    if let locatorChapter = bookmarkLoc.locator.title {
      chapter = locatorChapter
    } else if let tocLink = publication.tableOfContents.first(withHREF: bookmarkLoc.locator.href) {
      chapter = tocLink.title
    } else {
      chapter = nil
    }

    return NYPLReadiumBookmark(
      annotationId: nil,
      contentCFI: cfi,
      idref: idref,
      chapter: chapter,
      page: page,
      location: registryLoc?.locationString,
      progressWithinChapter: chapterProgress,
      progressWithinBook: totalProgress,
      creationTime: bookmarkLoc.creationDate,
      device: drmDeviceID)
  }

  class func make(fromServerAnnotation annotation: [String: Any],
                  annotationType: NYPLBookmarkSpec.Motivation,
                  bookID: String) -> NYPLReadiumBookmark? {

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
      return nil
    }

    guard let device = body[NYPLBookmarkSpec.Body.Device.key] as? String else {
      Log.error(#file, "Error reading `device` info from `body`:\(body)")
      return nil
    }

    let creationTime = NYPLBookmarkFactory.makeCreationTime(fromRFC3339timestamp:
      body[NYPLBookmarkSpec.Body.Time.key] as? String)

    guard
      let selector = target[NYPLBookmarkSpec.Target.Selector.key] as? [String: Any],
      let selectorValueEscJSON = selector[NYPLBookmarkSpec.Target.Selector.Value.key] as? String
      else {
        Log.error(#file, "Error reading required Selector Value from Target: \(target)")
        return nil
    }

    guard
      let selectorValueData = selectorValueEscJSON.data(using: String.Encoding.utf8),
      let selectorValueJSON = (try? JSONSerialization.jsonObject(with: selectorValueData)) as? [String: Any]
      else {
        Log.error(#file, "Error serializing `selector`. SelectorValue=\(selectorValueEscJSON)")
        return nil
    }

    let href = selectorValueJSON[NYPLBookmarkSpec.Target.Selector.Value.locatorChapterIDKey] as? String
    let legacyIDref = selectorValueJSON[NYPLBookmarkR1Key.idref.rawValue] as? String
    guard let chapterID = href ?? legacyIDref else {
        Log.error(#file, "Error reading chapter ID from server annotation. SelectorValue=\(selectorValueEscJSON)")
        return nil
    }

    let progress = selectorValueJSON[NYPLBookmarkSpec.Target.Selector.Value.locatorChapterProgressionKey]
    let legacyProgress = body["http://librarysimplified.org/terms/progressWithinChapter"]
    let progressWithinChapter = ((progress as? Double) ?? legacyProgress as? Double) ?? 0.0

    // non-essential info
    let serverCFI = selectorValueJSON[NYPLBookmarkSpec.Target.Selector.Value.legacyLocatorCFIKey] as? String
    let chapter = body["http://librarysimplified.org/terms/chapter"] as? String
    let bookProgress = body[NYPLBookmarkSpec.Body.BookProgress.key]
    let progressWithinBook = Float(bookProgress as? Double ?? 0.0)

    return NYPLReadiumBookmark(annotationId: annotationID,
                               contentCFI: serverCFI,
                               idref: chapterID,
                               chapter: chapter,
                               page: nil,
                               location: selectorValueEscJSON,
                               progressWithinChapter: Float(progressWithinChapter),
                               progressWithinBook: progressWithinBook,
                               creationTime: creationTime,
                               device:device)
  }

  // MARK:- Locators

  class func makeLocatorString(chapterHref: String, chapterProgression: Float) -> String? {
    guard chapterProgression >= 0.0, chapterProgression <= 1.0 else {
      return nil
    }

    return """
    {
      "\(NYPLBookmarkSpec.Target.Selector.Value.locatorTypeKey)": "\(NYPLBookmarkSpec.Target.Selector.Value.locatorTypeValue)",
      "\(NYPLBookmarkSpec.Target.Selector.Value.locatorChapterIDKey)": "\(chapterHref)",
      "\(NYPLBookmarkSpec.Target.Selector.Value.locatorChapterProgressionKey)": \(chapterProgression)
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
