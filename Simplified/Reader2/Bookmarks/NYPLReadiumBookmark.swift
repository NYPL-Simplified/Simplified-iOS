/// Bookmark representation for the Readium-1 epub renderer.
@objcMembers final class NYPLReadiumBookmark: NSObject {
  // I think this is the bookmark ID
  var annotationId:String?

  var chapter:String?
  var page:String?

  // location and contentCFI are location information generated from R1 reader
  // which are not available in R2, therefore they are now optionals
  var location:String
  var idref:String
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
    //Obj-C Nil Check
    guard let idref = idref else {
      Log.error(#file, "Bookmark failed init due to nil parameter.")
      return nil
    }
    self.annotationId = annotationId
    self.contentCFI = contentCFI
    self.idref = idref
    self.chapter = chapter ?? ""
    self.page = page ?? ""
    // This location structure originally comes from R1 Reader's Javascript
    // and its not available in R2, we are mimicking the structure
    // in order to pass the needed information to the server
    // TODO: SIMPLY-3644 refactor per spec
    self.location = location ?? "{\"idref\":\"\(idref)\",\"contentCFI\":\"\(contentCFI ?? "")\"}"
    self.progressWithinChapter = progressWithinChapter
    self.progressWithinBook = progressWithinBook
    self.time = time ?? NSDate().rfc3339String()
    self.device = device
  }
  
  init?(dictionary:NSDictionary)
  {
    if let contentCFI = dictionary["contentCFI"] as? String,
      let idref = dictionary["idref"] as? String,
      let location = dictionary["location"] as? String,
      let time = dictionary["time"] as? String {
        if let annotationID = dictionary["annotationId"] as? String, !annotationID.isEmpty {
          self.annotationId = annotationID
        } else {
          self.annotationId = nil
        }
        self.contentCFI = contentCFI
        self.idref = idref
        self.location = location
        self.time = time
        self.chapter = dictionary["chapter"] as? String
        self.page = dictionary["page"] as? String
        self.device = dictionary["device"] as? String
        if let progressChapter = (dictionary["progressWithinChapter"] as? NSNumber)?.floatValue {
          self.progressWithinChapter = progressChapter
        }
        if let progressBook = (dictionary["progressWithinBook"] as? NSNumber)?.floatValue {
          self.progressWithinBook = progressBook
        }
    } else {
      Log.error(#file, "Bookmark failed to init from dictionary.")
      return nil
    }
  }

  var dictionaryRepresentation:NSDictionary {
    return ["annotationId":self.annotationId ?? "",
            "contentCFI":self.contentCFI ?? "",
            "idref":self.idref,
            "chapter":self.chapter ?? "",
            "page":self.page ?? "",
            "location":self.location,
            "time":self.time,
            "device":self.device ?? "",
            "progressWithinChapter":self.progressWithinChapter,
            "progressWithinBook":self.progressWithinBook
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

