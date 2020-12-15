extension Notification.Name {
  static let NYPLProblemDocumentWasCached = Notification.Name("NYPLProblemDocumentWasCached")
}

@objc extension NSNotification {
  public static let NYPLProblemDocumentWasCached = Notification.Name.NYPLProblemDocumentWasCached
}

@objcMembers class NYPLProblemDocumentCacheManager : NSObject {
  struct DocWithTimestamp {
    let doc: NYPLProblemDocument
    let timestamp: Date
    
    init(_ document: NYPLProblemDocument) {
      doc = document
      timestamp = Date.init()
    }
  }
  
  // Static values
  static let CACHE_SIZE = 5
  static let shared = NYPLProblemDocumentCacheManager()
  
  // For Objective-C classes
  class func sharedInstance() -> NYPLProblemDocumentCacheManager {
    return NYPLProblemDocumentCacheManager.shared
  }
  
  // Member values
  private var cache: [String : [DocWithTimestamp]]
  
  override init() {
    cache = [String : [DocWithTimestamp]]()
    super.init()
  }
  
  // MARK: - Write
  
  @objc func cacheProblemDocument(_ doc: NYPLProblemDocument, key: String) {
    let timeStampDoc = DocWithTimestamp.init(doc)
    guard var vals = cache[key] else {
      cache[key] = [timeStampDoc]
      NotificationCenter.default.post(name: NSNotification.Name.NYPLProblemDocumentWasCached, object: doc)
      return
    }
    
    if vals.count >= NYPLProblemDocumentCacheManager.CACHE_SIZE {
      vals.removeFirst(1)
      vals.append(timeStampDoc)
      cache[key] = vals
    }
    NotificationCenter.default.post(name: NSNotification.Name.NYPLProblemDocumentWasCached, object: doc)
  }
  
  @objc(clearCachedDocForBookIdentifier:)
  func clearCachedDoc(_ key: String) {
    cache[key] = []
  }
  
  // MARK: - Read
  
  func getLastCachedDoc(_ key: String) -> NYPLProblemDocument? {
    guard let cachedDocuments = cache[key] else {
      return nil
    }
    return cachedDocuments.last?.doc
  }
}
