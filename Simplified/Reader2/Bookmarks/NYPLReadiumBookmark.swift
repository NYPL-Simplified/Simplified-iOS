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
  /// The bookmark ID.
  var annotationId:String?

  var chapter:String?
  var page:String?

  var location:String //TODO: SIMPLY-3670 could be a computed property
  var idref:String

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
  var progressWithinBook:Float = 0.0

  var percentInChapter:String {
    return (self.progressWithinChapter * 100).roundTo(decimalPlaces: 0)
  }
  var percentInBook:String {
    return (self.progressWithinBook * 100).roundTo(decimalPlaces: 0)
  }
  
  var device:String?

  let creationTime: Date

  /// Date formatted as per RFC 3339
  var timestamp: String {
    return (creationTime as NSDate).rfc3339String()
  }

  /// Deprecated. 
  init?(annotationId:String?,
        contentCFI:String?,
        idref:String?, //TODO: SIMPLY-3670 if we make it from R2, this value will actually be an href
        chapter:String?,
        page:String?,
        location:String?,//TODO: SIMPLY-3670 contains redundant info
        progressWithinChapter:Float,
        progressWithinBook:Float,
        creationTime:Date,
        device:String?)
  {
    guard let idref = idref else {
      Log.error(#file, "Bookmark creation failed init due to nil `idref`.")
      return nil
    }
    self.annotationId = annotationId
    self.contentCFI = contentCFI
    self.idref = idref
    self.chapter = chapter ?? ""
    self.page = page ?? ""

    guard let loc = location ?? NYPLBookmarkFactory
      .makeLocatorString(chapterHref: idref,
                         chapterProgression: progressWithinChapter) else {
                          return nil
    }

    self.location = loc
    self.progressWithinChapter = progressWithinChapter
    self.progressWithinBook = progressWithinBook
    self.creationTime = creationTime
    self.device = device
  }
  
  init?(dictionary:NSDictionary)
  {
    guard
      let idref = dictionary[NYPLBookmarkDictionaryRepresentation.idrefKey] as? String,
      let location = dictionary[NYPLBookmarkDictionaryRepresentation.locationKey] as? String
      else {
        Log.error(#file, "Bookmark creation from dictionary failed: missing required info:\(dictionary).")
        return nil
    }

    if let annotationID = dictionary[NYPLBookmarkDictionaryRepresentation.annotationIdKey] as? String, !annotationID.isEmpty {
      self.annotationId = annotationID
    } else {
      self.annotationId = nil
    }

    self.contentCFI = dictionary[NYPLBookmarkDictionaryRepresentation.cfiKey] as? String
    self.idref = idref
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
    return [
      NYPLBookmarkDictionaryRepresentation.annotationIdKey: self.annotationId ?? "",
      NYPLBookmarkDictionaryRepresentation.cfiKey: self.contentCFI ?? "",
      NYPLBookmarkDictionaryRepresentation.idrefKey: self.idref,
      NYPLBookmarkDictionaryRepresentation.chapterKey: self.chapter ?? "",
      NYPLBookmarkDictionaryRepresentation.pageKey: self.page ?? "",
      NYPLBookmarkDictionaryRepresentation.locationKey: self.location,
      NYPLBookmarkDictionaryRepresentation.timeKey: self.timestamp,
      NYPLBookmarkDictionaryRepresentation.deviceKey: self.device ?? "",
      NYPLBookmarkDictionaryRepresentation.chapterProgressKey: self.progressWithinChapter,
      NYPLBookmarkDictionaryRepresentation.bookProgressKey: self.progressWithinBook
    ]
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
      return self.idref == other.idref
        && self.progressWithinBook =~= other.progressWithinBook
        && self.progressWithinChapter =~= other.progressWithinChapter
        && self.chapter == other.chapter
    }
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

