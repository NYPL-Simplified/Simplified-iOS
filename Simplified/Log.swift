import Firebase
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
    #if !DEBUG
      guard level != .debug else {
        return
      }
    #endif
    
    // Generate timestamp
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
    let timestamp = dateFormatter.string(from: Date())
    
    // Format string
    let formattedMsg = "[\(levelToString(level))] [\(timestamp)] \(tag): \(message)\(error == nil ? "" : "\n\(error!)")\n"

    #if targetEnvironment(simulator)
    NSLog(formattedMsg)
    #elseif DEBUG
    if level != .debug {
      Crashlytics.crashlytics().log(format: "%@", arguments: getVaList([formattedMsg]))
    } else {
      NSLog(formattedMsg)
    }
    #else
    Crashlytics.crashlytics().log("\(formattedMsg)")
    #endif
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
