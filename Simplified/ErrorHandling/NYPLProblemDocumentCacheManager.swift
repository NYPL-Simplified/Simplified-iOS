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
  var lastCachedDoc: DocWithTimestamp?
  var lastCachedKey: String?
  var cache: [String : [DocWithTimestamp]]
  
  override init() {
    cache = [String : [DocWithTimestamp]]()
    lastCachedDoc = nil
    lastCachedKey = nil
    super.init()
  }
  
  @objc func cacheProblemDocument(_ doc: NYPLProblemDocument, key: String) {
    lastCachedKey = key
    lastCachedDoc = DocWithTimestamp.init(doc)
    guard var vals = cache[key] else {
      cache[key] = [lastCachedDoc!]
      NotificationCenter.default.post(name: NSNotification.Name.NYPLProblemDocumentWasCached, object: doc)
      return
    }
    
    if vals.count >= NYPLProblemDocumentCacheManager.CACHE_SIZE {
      vals.removeFirst(1)
      vals.append(lastCachedDoc!)
      cache[key] = vals
    }
    NotificationCenter.default.post(name: NSNotification.Name.NYPLProblemDocumentWasCached, object: doc)
  }
  
  func getLastCachedDoc(_ key: String) -> NYPLProblemDocument? {
    if lastCachedKey == key {
      return lastCachedDoc?.doc
    }
    return nil
  }
}
