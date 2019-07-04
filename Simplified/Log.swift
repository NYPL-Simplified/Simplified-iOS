import Foundation

final class Log: NSObject {
  
  @objc static let logUrl = try! FileManager.default.url(
    for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    .appendingPathComponent("log.log")
  
  @objc static let logQueue = DispatchQueue(label: Bundle.main.bundleIdentifier!
    + ".swiftLogger")
  
  enum Level {
    case debug
    case info
    case warn
    case error
  }
  
  fileprivate class func levelToString(_ level: Level) -> String {
    switch level {
    case .debug:
      return "DEBUG"
    case .info:
      return "INFO"
    case .warn:
      return "WARNING"
    case .error:
      return "ERROR"
    }
  }
  
  class func log(_ level: Level, _ tag: String, _ message: String, error: Error? = nil) {
    #if DEBUG
      let shouldLog = true
    #else
      let shouldLog = level != .debug
    #endif
    
    if !shouldLog {
      return
    }
    
    // Generate timestamp
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
    let timestamp = dateFormatter.string(from: Date())
    
    // Format string
    let formattedMsg = "[\(levelToString(level))] [\(timestamp)] \(tag): \(message)\(error == nil ? "" : "\n\(error!)")\n"
    
    // Write to console
    NSLog(formattedMsg)
    
    // Write to file
    var overwrite = false
    if let size = try? FileManager.default.attributesOfItem(atPath: logUrl.path)[FileAttributeKey.size] as! Int {
      if size > 1048576 {
        overwrite = true
      }
    }
    if overwrite {
      try? formattedMsg.write(to: logUrl, atomically: false, encoding: .utf8)
    } else {
      if let outputStream = OutputStream(url: logUrl, append: true) {
        let buf = [UInt8](formattedMsg.utf8)
        outputStream.open()
        outputStream.write(buf, maxLength: buf.count)
        outputStream.close()
      }
    }
  }
  
  @objc class func log(_ message: String) {
    log(Level.info, "", message, error: nil)
  }
  
  class func debug(_ tag: String, _ message: String, error: Error? = nil) {
    log(.debug, tag, message, error: error)
  }
  
  class func info(_ tag: String, _ message: String, error: Error? = nil) {
    log(.info, tag, message, error: error)
  }
  
  class func warn(_ tag: String, _ message: String, error: Error? = nil) {
    log(.warn, tag, message, error: error)
  }
  
  class func error(_ tag: String, _ message: String, error: Error? = nil) {
    log(.error, tag, message, error: error)
  }
}
