import R2Shared
import NYPLUtilities

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
  static let deviceKey = "device"
  static let chapterProgressKey = "progressWithinChapter"
  static let bookProgressKey = "progressWithinBook"
}

/// Internal representation of an annotation. This may represent an actual
/// user bookmark as well as the "bookmark" of the last read position in a book.
@objcMembers final class NYPLReadiumBookmark: NSObject, NYPLBookmark {
  /// The bookmark ID. Optional because only the server assigns it.
  var annotationId:String?

  let chapter: String?

  /// R2 chapter ID.
  let href: String?

  /// R1 chapter ID.
  let idref: String?

  /// Expresses the fact that the chapter ID can come from either a `href` (R2)
  /// or a `idref` (R1) at run time.
  enum ChapterID {
    case href(String)
    case idref(String)
  }

  /// The actual chapter ID we currently have.
  ///
  /// Per NYPLBookmarkSpec, a bookmark MUST have a chapter ID in order to
  /// be a functioning bookmark. However, when a NYPLReadiumBookmark object
  /// is created, the chapter ID can be either an `href` (if bookmark was
  /// created on R2) or a `idref` (if created on R1). The `chapterID` property
  /// allows the bookmark to create a valid `location` string (aka "Selector
  /// Value", per `NYPLBookmarkSpec`) which would not be possible otherwise.
  let chapterID: ChapterID

  var location: String {
    switch chapterID {
    case .href(let href):
      return NYPLReadiumBookmarkFactory.makeLocatorString(
        chapterHref: href,
        chapterProgression: progressWithinChapter)
    case .idref(let idref):
      return NYPLReadiumBookmarkFactory.makeLegacyLocatorString(
        idref: idref,
        chapterProgression: progressWithinChapter,
        cfi: contentCFI ?? "")
    }
  }

  /// The CFI is location information generated from the R1 reader
  /// which is not usable in R2.
  ///
  /// A CFI value refers to the content fragment identifier used to point
  /// to a specific element within the specified spine item. This was
  /// consumed by R1, but there has always been very little consistency
  /// in the values consumed by Library Simplified applications between
  /// platforms, hence its legacy and optional status.
  ///
  /// - Important: This is _deprecated_.
  let contentCFI: String?

  let progressWithinChapter: Float
  let progressWithinBook: Float?

  var percentInChapter:String {
    return (self.progressWithinChapter * 100).roundTo(decimalPlaces: 0)
  }

  /// The device ID this bookmark was created on.
  ///
  /// This is used during the bookmark and reading progress syncing process to
  /// understand if a bookmark needs to be added to the current list.
  /// - See: NYPLReaderBookmarksBusinessLogic::updateLocalBookmarks(...)
  /// - See: NYPLLatReadPositionSynchronizer::syncReadPosition(...)
  let device: String?

  let creationTime: Date

  /// Creation date-time formatted per RFC 3339.
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
  ///   - location: _Deprecated_. This can be derived from `href` and
  ///   `progressWithinChapter`. Currently used as a backup for other parameters.
  ///   - progressWithinChapter: A value between [0...1] to identify the
  ///   position within the chapter. Required.
  ///   - progressWithinBook: A value between [0...1] to express the progress
  ///   over the entire book. Used for display purposes.
  ///   - time: The date-time the bookmark was created on.
  ///   - device: The device this bookmark was created on.
  init?(annotationId:String?,
        contentCFI:String?,
        href: String?,
        idref: String?,
        chapter:String?,
        location:String?,
        progressWithinChapter:Float,
        progressWithinBook: NSNumber?,
        creationTime:Date,
        device:String?)
  {
    var hrefFromLocation: String?
    var idrefFromLocation: String?
    if let loc = location, let tuple = NYPLReadiumBookmarkFactory.parseLocatorString(loc) {
      (hrefFromLocation, idrefFromLocation, _) = tuple
    }

    self.href = href ?? hrefFromLocation
    self.idref = idref ?? idrefFromLocation

    if let href = self.href {
      self.chapterID = .href(href)
    } else if let idref = self.idref {
      self.chapterID = .idref(idref)
    } else {
      Log.error(#file, "Attempting to initialize bookmark with neither a `href` or `idref`. Location: \(location ?? "")")
      return nil
    }

    self.annotationId = annotationId
    self.contentCFI = contentCFI
    self.chapter = chapter ?? ""
    self.progressWithinChapter = progressWithinChapter
    self.progressWithinBook = progressWithinBook?.floatValue
    self.creationTime = creationTime
    self.device = device
  }

  /// Initialize from a dictionary representation, usually derived from
  /// the `NYPLBookRegistry`.
  ///
  /// - Parameter dictionary: Dictionary representation of the bookmark. See
  /// `NYPLBookmarkDictionaryRepresentation` for valid keys.
  init?(dictionary:NSDictionary) {
    var hrefFromLocation: String?
    var idrefFromLocation: String?
    var progressFromLocation: Double?
    let location = dictionary[NYPLBookmarkDictionaryRepresentation.locationKey] as? String
    if let loc = location, let tuple = NYPLReadiumBookmarkFactory.parseLocatorString(loc) {
      (hrefFromLocation, idrefFromLocation, progressFromLocation) = tuple
    }

    self.href = dictionary[NYPLBookmarkDictionaryRepresentation.hrefKey] as? String ?? hrefFromLocation
    self.idref = dictionary[NYPLBookmarkDictionaryRepresentation.idrefKey] as? String ?? idrefFromLocation

    if let href = self.href {
      self.chapterID = .href(href)
    } else if let idref = self.idref {
      self.chapterID = .idref(idref)
    } else {
      Log.error(#file, "Bookmark creation from dictionary failed. Missing resource identifier: \(dictionary)")
      return nil
    }

    if let annotationID = dictionary[NYPLBookmarkDictionaryRepresentation.annotationIdKey] as? String, !annotationID.isEmpty {
      self.annotationId = annotationID
    } else {
      self.annotationId = nil
    }

    self.contentCFI = dictionary[NYPLBookmarkDictionaryRepresentation.cfiKey] as? String
    let time = dictionary[NYPLBookmarkDictionaryRepresentation.timeKey] as? String
    self.creationTime = NYPLReadiumBookmarkFactory.makeCreationTime(fromRFC3339timestamp: time)
    self.chapter = dictionary[NYPLBookmarkDictionaryRepresentation.chapterKey] as? String
    self.device = dictionary[NYPLBookmarkDictionaryRepresentation.deviceKey] as? String

    if let progressChapter = dictionary[NYPLBookmarkDictionaryRepresentation.chapterProgressKey] as? NSNumber {
      self.progressWithinChapter = progressChapter.floatValue
    } else if let progressFromLocation = progressFromLocation {
      self.progressWithinChapter = Float(progressFromLocation)
    } else {
      self.progressWithinChapter = 0.0
    }

    if let progressBook = dictionary[NYPLBookmarkDictionaryRepresentation.bookProgressKey] as? NSNumber {
      self.progressWithinBook = progressBook.floatValue
    } else {
      self.progressWithinBook = nil
    }
  }
}

// MARK:- Representations

extension NYPLReadiumBookmark {
  var dictionaryRepresentation:NSDictionary {
    let dict: NSMutableDictionary = [
      NYPLBookmarkDictionaryRepresentation.annotationIdKey: self.annotationId ?? "",
      NYPLBookmarkDictionaryRepresentation.cfiKey: self.contentCFI ?? "",
      NYPLBookmarkDictionaryRepresentation.hrefKey: self.href ?? "",
      NYPLBookmarkDictionaryRepresentation.chapterKey: self.chapter ?? "",
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

  override var description: String {
    return "\(dictionaryRepresentation)"
  }

  /// Creates a Locator object that can be used in Readium 2.
  ///
  /// Not every single piece of data contained in this bookmark is considered
  /// for this conversion: only what's strictly necessary to be able to point
  /// at the same location inside the `Publication`.
  ///
  /// - Complexity: O(*n*) where *n* is the length of the internal
  /// `Publication.readingOrder` data structure.
  ///
  /// - Parameter publication: The R2 publication object where the bookmark is
  /// located.

  /// - Returns: A Locator pointing at the same position this bookmark is
  /// pointing to.
  func locator(forPublication publication: Publication) -> Locator? {
    let href: String
    if let r2href = self.href {
      href = r2href
    } else if let idref = self.idref, let r1href = publication.link(withIDref: idref)?.href {
      href = r1href
    } else {
      return nil
    }

    let totalProgress = (progressWithinBook != nil) ? Double(progressWithinBook!) : nil
    let locations = Locator.Locations(progression: Double(progressWithinChapter),
                                      totalProgression: totalProgress)
    return Locator(href: href,
                   type: publication.metadata.type ?? MediaType.xhtml.string,
                   title: chapter,
                   locations: locations)
  }
}

