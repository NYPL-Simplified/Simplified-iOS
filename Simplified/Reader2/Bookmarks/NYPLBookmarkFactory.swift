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
      time: (bookmarkLoc.creationDate as NSDate).rfc3339String(),
      device: drmDeviceID)
  }

  class func make(fromServerBookmark annotation: [String: Any],
                  bookID: String) -> NYPLReadiumBookmark? {
    return make(fromServerAnnotation: annotation,
                annotationType: .bookmark,
                bookID: bookID)
  }

  class func make(fromServerAnnotation annotation: [String: Any],
                  annotationType: NYPLBookmarkSpec.Motivation,
                  bookID: String) -> NYPLReadiumBookmark? {

    guard let annotationID = annotation[NYPLBookmarkSpec.Id.key] as? String else {
      Log.error(#file, "Missing AnnotationID:\(annotation)")
      return nil
    }

    guard let target = annotation[NYPLBookmarkSpec.Target.key] as? [String: AnyObject],
      let source = target[NYPLBookmarkSpec.Target.Source.key] as? String,
      let motivation = annotation[NYPLBookmarkSpec.Motivation.key] as? String else {
        Log.error(#file, "Error parsing required key/values for target.")
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

    guard
      let body = annotation[NYPLBookmarkSpec.Body.key] as? [String: AnyObject],
      let device = body[NYPLBookmarkSpec.Body.Device.key] as? String,
      let time = body[NYPLBookmarkSpec.Body.Time.key] as? String,

      // TODO: SIMPLY-3655 update to R2 spec or remove
      let progressWithinChapter = (body["http://librarysimplified.org/terms/progressWithinChapter"] as? NSNumber)?.floatValue,
      let progressWithinBook = (body["http://librarysimplified.org/terms/progressWithinBook"] as? NSNumber)?.floatValue
      else {
        Log.error(#file, "Error reading required bookmark key/values from body")
        return nil
    }

    guard
      let selector = target[NYPLBookmarkSpec.Target.Selector.key] as? [String: AnyObject],
      let selectorValueEscJSON = selector[NYPLBookmarkSpec.Target.Selector.Value.key] as? String
      else {
        Log.error(#file, "Error reading required Selector Value from Target.")
        return nil
    }

    guard
      let selectorValueData = selectorValueEscJSON.data(using: String.Encoding.utf8),
      let selectorValueJSON = (try? JSONSerialization.jsonObject(with: selectorValueData,
                                                                 options: [])) as? [String: Any],
      // TODO: SIMPLY-3655 update to R2 spec
      let idref = selectorValueJSON[NYPLBookmarkR1Key.idref.rawValue] as? String
      else {
        Log.error(#file, "Error serializing serverCFI into JSON. Selector.Value=\(selectorValueEscJSON)")
        return nil
    }

    let serverCFI = selectorValueJSON[NYPLBookmarkSpec.Target.Selector.Value.legacyLocatorCFIKey] as? String
    let chapter = body["http://librarysimplified.org/terms/chapter"] as? String

    return NYPLReadiumBookmark(annotationId: annotationID,
                               contentCFI: serverCFI,
                               idref: idref,
                               chapter: chapter,
                               page: nil,
                               location: selectorValueEscJSON,
                               progressWithinChapter: progressWithinChapter,
                               progressWithinBook: progressWithinBook,
                               time:time,
                               device:device)
  }
}
