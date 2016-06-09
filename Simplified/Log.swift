import Foundation

final class Log {
  
  enum Level {
    case Debug
    case Info
    case Warn
    case Error
  }
  
  private class func levelToString(level: Level) -> String {
    switch level {
    case .Debug:
      return "DEBUG"
    case .Info:
      return "INFO"
    case .Warn:
      return "WARNING"
    case .Error:
      return "ERROR"
    }
  }
  
  class func log(level: Level, _ tag: String, _ message: String, error: ErrorType? = nil) {
    #if DEBUG
      let shouldLog = true
    #else
      let shouldLog = level != .Debug
    #endif
    
    if shouldLog {
      NSLog("[\(levelToString(level))] \(tag): \(message)\(error == nil ? "" : "\n\(error)")")
    }
  }
  
  class func debug(tag: String, _ message: String, error: ErrorType? = nil) {
    log(.Debug, tag, message, error: error)
  }
  
  class func info(tag: String, _ message: String, error: ErrorType? = nil) {
    log(.Info, tag, message, error: error)
  }
  
  class func warn(tag: String, _ message: String, error: ErrorType? = nil) {
    log(.Warn, tag, message, error: error)
  }
  
  class func error(tag: String, _ message: String, error: ErrorType? = nil) {
    log(.Error, tag, message, error: error)
  }
}
