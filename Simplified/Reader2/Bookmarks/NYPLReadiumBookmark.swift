/// This class specifies the keys used to represent a NYPLReadiumBookmark
/// as a dictionary.
///
/// The dictionary representation is used internally in SimplyE / OE
/// to persist bookmark info to disk. It's only loosely related to the
/// `NYPLBookmarkSpec` which instead specifies a cross-platform contract
/// for bookmark representation.
///
/// - Important: These keys should not change. If they did, that will mean
/// that a user won't be able to retrieve the bookmarks from disk anymore.
///
@objc class NYPLBookmarkDictionaryRepresentation: NSObject {
  static let annotationIdKey = "annotationId"
  @objc static let hrefKey = "href"
  @objc static let idrefKey = "idref"
  @objc static let locationKey = "location"
  @objc static let cfiKey = "contentCFI"
  static let timeKey = "time"
  static let chapterKey = "chapter"
  static let pageKey = "page"
  static let deviceKey = "device"
  static let chapterProgressKey = "progressWithinChapter"
  static let bookProgressKey = "progressWithinBook"
}

/// Internal representation of an annotation. This may represent an actual
/// user bookmark as well as the "bookmark" of the last read position in a book.
@objcMembers final class NYPLReadiumBookmark: NSObject {
  /// The bookmark ID. Optional because only the server assigns it.
  var annotationId:String?

  var chapter:String?
  var page:String?

  var location:String //TODO: SIMPLY-3670 could be a computed property

  var href: String?
  var idref: String?

  /// The CFI is location information generated from the R1 reader
  /// which is not usable in R2.
  ///
  /// A CFI value refers to the content fragment identifier used to point
  /// to a specific element within the specified spine item. This was
  /// consumed by R1, but there has always been very little consistency
  /// in the values consumed by Library Simplified applications between
  /// platforms, hence its legacy and optional status.
  var contentCFI:String?

  var progressWithinChapter:Float = 0.0
  var progressWithinBook:Float?

  var percentInChapter:String {
    return (self.progressWithinChapter * 100).roundTo(decimalPlaces: 0)
  }

  /// The device ID this bookmark was created on.
  ///
  /// This is used during the bookmark and reading progress syncing process to
  /// understand if a bookmark needs to be added to the current list.
  /// - See: NYPLReaderBookmarksBusinessLogic::updateLocalBookmarks(...)
  /// - See: NYPLLatReadPositionSynchronizer::syncReadPosition(...)
  var device:String?

  let creationTime: Date

  /// Date formatted as per RFC 3339
  var timestamp: String {
    return creationTime.rfc3339String
  }

  /// Designated initializer.
  ///
  /// Creates a bookmark in R2 format. This is not usable in R1-dependent code.
  ///
  /// - Parameters:
  ///   - annotationId: The bookmark ID, if known.
  ///   - contentCFI: _Deprecated_. Unused by R2.
  ///   - href: The chapter identifier. Required to be able to jump to the
  ///   bookmark position.
  ///   - idref: _Deprecated_. The legacy chapter identifier.
  ///   Required if `href` is missing.
  ///   - chapter: The chapter title, for display purposes.
  ///   - page: The page number, for display purposes.
  ///   - location: _Deprecated_. This can be derived from `href` and
  ///   `progressWithinChapter`.
  ///   - progressWithinChapter: A value between [0...1] to identify the
  ///   position within the chapter. Required.
  ///   - progressWithinBook: A value between [0...1] to express the progress
  ///   over the entire book. Used for display purposes.
  ///   - time: A String formatted per RFC 3339 containing the date-time in
  ///   UTC timezone the bookmark was created.
  ///   - device: The device this bookmark was created on.
  init?(annotationId:String?,
        contentCFI:String?,
        href: String?,
        idref: String?,
        chapter:String?,
        page:String?,
        location:String?,
        progressWithinChapter:Float,
        progressWithinBook: NSNumber?,
        creationTime:Date,
        device:String?)
  {
    guard href != nil || idref != nil else {
      Log.error(#file, "Attempting to initialize bookmark with neither a `href` or `idref`. Location: \(location ?? "")")
      return nil
    }

    self.href = href
    self.idref = idref
    self.annotationId = annotationId
    self.contentCFI = contentCFI
    self.chapter = chapter ?? ""
    self.page = page ?? ""

    var r2loc: String? = nil
    var r1loc: String? = nil
    if let href = href {
      r2loc = NYPLBookmarkFactory.makeLocatorString(
        chapterHref: href,
        chapterProgression: progressWithinChapter)
    }
    //TODO: SIMPLY-3670 this seems unneeded? the cfi is useless anyway
    // instead, maybe parse `location` and see if `chapterProgression` can be
    // extracted from there.
    if let idref = idref, let cfi = contentCFI {
      r1loc = NYPLBookmarkFactory.makeLegacyLocatorString(
        idref: idref,
        chapterProgression: progressWithinChapter,
        cfi: cfi)
    }
    guard let loc = (r2loc ?? r1loc) ?? location else {
      return nil
    }
    self.location = loc

    self.progressWithinChapter = progressWithinChapter
    self.progressWithinBook = progressWithinBook?.floatValue
    self.creationTime = creationTime
    self.device = device
  }
  
  init?(dictionary:NSDictionary) {
    let href = dictionary[NYPLBookmarkDictionaryRepresentation.hrefKey] as? String
    let idref = dictionary[NYPLBookmarkDictionaryRepresentation.idrefKey] as? String

    guard href != nil || idref != nil else {
      Log.error(#file, "Bookmark creation from dictionary failed. Missing resource identifier: \(dictionary)")
      return nil
    }

    // TODO: SIMPLY-3670
    guard
      let location = dictionary[NYPLBookmarkDictionaryRepresentation.locationKey] as? String
      else {
        Log.error(#file, "Bookmark creation from dictionary failed. Missing location: \(dictionary)")
        return nil
    }

    if let annotationID = dictionary[NYPLBookmarkDictionaryRepresentation.annotationIdKey] as? String, !annotationID.isEmpty {
      self.annotationId = annotationID
    } else {
      self.annotationId = nil
    }

    self.contentCFI = dictionary[NYPLBookmarkDictionaryRepresentation.cfiKey] as? String
    self.idref = idref
    self.href = href
    self.location = location
    let time = dictionary[NYPLBookmarkDictionaryRepresentation.timeKey] as? String
    self.creationTime = NYPLBookmarkFactory.makeCreationTime(fromRFC3339timestamp: time)
    self.chapter = dictionary[NYPLBookmarkDictionaryRepresentation.chapterKey] as? String
    self.page = dictionary[NYPLBookmarkDictionaryRepresentation.pageKey] as? String
    self.device = dictionary[NYPLBookmarkDictionaryRepresentation.deviceKey] as? String

    if let progressChapter = dictionary[NYPLBookmarkDictionaryRepresentation.chapterProgressKey] as? NSNumber {
      self.progressWithinChapter = progressChapter.floatValue
    }

    if let progressBook = dictionary[NYPLBookmarkDictionaryRepresentation.bookProgressKey] as? NSNumber {
      self.progressWithinBook = progressBook.floatValue
    }
  }

  var dictionaryRepresentation:NSDictionary {
    let dict: NSMutableDictionary = [
      NYPLBookmarkDictionaryRepresentation.annotationIdKey: self.annotationId ?? "",
      NYPLBookmarkDictionaryRepresentation.cfiKey: self.contentCFI ?? "",
      NYPLBookmarkDictionaryRepresentation.hrefKey: self.href ?? "",
      NYPLBookmarkDictionaryRepresentation.chapterKey: self.chapter ?? "",
      NYPLBookmarkDictionaryRepresentation.pageKey: self.page ?? "",
      NYPLBookmarkDictionaryRepresentation.locationKey: self.location,
      NYPLBookmarkDictionaryRepresentation.timeKey: self.timestamp,
      NYPLBookmarkDictionaryRepresentation.deviceKey: self.device ?? "",
      NYPLBookmarkDictionaryRepresentation.chapterProgressKey: self.progressWithinChapter,
    ]

    if let bookProgress = self.progressWithinBook {
      dict[NYPLBookmarkDictionaryRepresentation.bookProgressKey] = bookProgress
    }

    return dict
  }
  
  override func isEqual(_ object: Any?) -> Bool {
    guard let other = object as? NYPLReadiumBookmark else {
      return false
    }

    if let contentCFI = self.contentCFI,
      let otherContentCFI = other.contentCFI,
      contentCFI.count > 0 && otherContentCFI.count > 0 {
      // R1
      return self.idref == other.idref
        && self.contentCFI == other.contentCFI
        && self.location == other.location
        && self.chapter == other.chapter
    } else {
      // R2
      return self.href == other.href
        && self.progressWithinChapter =~= other.progressWithinChapter
    }
  }

  @objc func lessThan(_ bookmark: NYPLReadiumBookmark) -> Bool {
    if let progress1 = progressWithinBook, let progress2 = bookmark.progressWithinBook {
      return progress1 < progress2
    }

    if href == bookmark.href {
      return progressWithinChapter < bookmark.progressWithinChapter
    }

    return creationTime < bookmark.creationTime
  }

}

extension NYPLReadiumBookmark {
  override var description: String {
    return "\(dictionaryRepresentation)"
  }
}

extension NYPLReadiumBookmark {
  func serializableRepresentation(forMotivation motivation: NYPLBookmarkSpec.Motivation,
                                  bookID: String) -> [String: Any] {

    let extras = NYPLBookmarkSpec.Body.BookProgress(value: progressWithinBook)
    let spec = NYPLBookmarkSpec(id: annotationId,
                                time: creationTime,
                                device: device ?? "",
                                bodyOthers: extras.dictionaryValue,
                                motivation: motivation,
                                bookID: bookID,
                                selectorValue: location)

    return spec.dictionaryForJSONSerialization()
  }
}

