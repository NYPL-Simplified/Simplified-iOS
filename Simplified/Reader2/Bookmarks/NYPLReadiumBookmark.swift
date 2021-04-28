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
  fileprivate static let annotationIdKey = "annotationId"
  @objc static let idrefKey = "idref"
  @objc static let locationKey = "location"
  @objc static let cfiKey = "contentCFI"
  fileprivate static let timeKey = "time"
  fileprivate static let chapterKey = "chapter"
  fileprivate static let pageKey = "page"
  fileprivate static let deviceKey = "device"
  fileprivate static let chapterProgressKey = "progressWithinChapter"
  fileprivate static let bookProgressKey = "progressWithinBook"
}

/// Internal representation of an annotation. This may represent an actual
/// user bookmark as well as the "bookmark" of the last read position in a book.
@objcMembers final class NYPLReadiumBookmark: NSObject {
  /// The bookmark ID.
  var annotationId:String?

  var chapter:String?
  var page:String?

  var location:String
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

  /// Date formatted as per RFC 3339
  let time:String

  /// Deprecated. 
  init?(annotationId:String?,
        contentCFI:String?,
        idref:String?,
        chapter:String?,
        page:String?,
        location:String?,
        progressWithinChapter:Float,
        progressWithinBook:Float,
        time:String?,
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

    // TODO: SIMPLY-3655 refactor per spec
    // This location structure originally comes from R1 Reader's Javascript
    // and its not available in R2, we are mimicking the structure
    // in order to pass the needed information to the server
    self.location = location ?? "{\"idref\":\"\(idref)\",\"contentCFI\":\"\(contentCFI ?? "")\"}"

    self.progressWithinChapter = progressWithinChapter
    self.progressWithinBook = progressWithinBook
    self.time = time ?? NSDate().rfc3339String()
    self.device = device
  }
  
  init?(dictionary:NSDictionary)
  {
    guard let contentCFI = dictionary[NYPLBookmarkDictionaryRepresentation.cfiKey] as? String,
      let idref = dictionary[NYPLBookmarkDictionaryRepresentation.idrefKey] as? String,
      let location = dictionary[NYPLBookmarkDictionaryRepresentation.locationKey] as? String,
      let time = dictionary[NYPLBookmarkDictionaryRepresentation.timeKey] as? String else {
        Log.error(#file, "Bookmark failed to init from dictionary.")
        return nil
    }

    if let annotationID = dictionary[NYPLBookmarkDictionaryRepresentation.annotationIdKey] as? String, !annotationID.isEmpty {
      self.annotationId = annotationID
    } else {
      self.annotationId = nil
    }
    self.contentCFI = contentCFI
    self.idref = idref
    self.location = location
    self.time = time
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
      NYPLBookmarkDictionaryRepresentation.timeKey: self.time,
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

