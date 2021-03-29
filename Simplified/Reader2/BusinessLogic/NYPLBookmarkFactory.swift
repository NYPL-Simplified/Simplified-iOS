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

  func make(from bookmarkLoc: NYPLBookmarkR2Location,
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

      cfi = registryLocationDict["contentCFI"] as? String

      // backup idref from R1 in case parsing from R2 fails for some reason
      idref = registryLocationDict["idref"] as? String
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

  class func make(fromServerAnnotation annotation: [String: Any],
                  bookID: String) -> NYPLReadiumBookmark? {

    guard let target = annotation["target"] as? [String: AnyObject],
      let source = target["source"] as? String,
      let annotationID = annotation["id"] as? String,
      let motivation = annotation["motivation"] as? String else {
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

    guard motivation.contains("bookmarking") else {
      return nil
    }

    guard let selector = target["selector"] as? [String: AnyObject],
      let serverCFI = selector["value"] as? String,
      let body = annotation["body"] as? [String: AnyObject] else {
        Log.error(#file, "ServerCFI could not be parsed.")
        return nil
    }

    guard let device = body["http://librarysimplified.org/terms/device"] as? String,
      let time = body["http://librarysimplified.org/terms/time"] as? String,
      let progressWithinChapter = (body["http://librarysimplified.org/terms/progressWithinChapter"] as? NSNumber)?.floatValue,
      let progressWithinBook = (body["http://librarysimplified.org/terms/progressWithinBook"] as? NSNumber)?.floatValue else {
        Log.error(#file, "Error reading required bookmark key/values from body")
        return nil
    }
    let chapter = body["http://librarysimplified.org/terms/chapter"] as? String

    guard let data = serverCFI.data(using: String.Encoding.utf8),
      let serverCfiJsonObject = (try? JSONSerialization.jsonObject(with: data,
                                                                   options: [])) as? [String: Any],
      let serverIdrefString = serverCfiJsonObject["idref"] as? String
      else {
        Log.error(#file, "Error serializing serverCFI into JSON.")
        return nil
    }

    var serverCfiString: String?

    if let serverCfiJson = serverCfiJsonObject["contentCFI"] as? String {
      serverCfiString = serverCfiJson
    }

    return NYPLReadiumBookmark(annotationId: annotationID,
                               contentCFI: serverCfiString,
                               idref: serverIdrefString,
                               chapter: chapter,
                               page: nil,
                               location: serverCFI,
                               progressWithinChapter: progressWithinChapter,
                               progressWithinBook: progressWithinBook,
                               time:time,
                               device:device)
  }
}
