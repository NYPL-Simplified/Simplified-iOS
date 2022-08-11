import os
import Foundation
import FirebaseCrashlytics

final class Log: NSObject {
  static var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return formatter
  }()

  private class func levelToString(_ level: OSLogType) -> String {
    switch level {
    case .debug:
      return "DEBUG"
    case .info:
      return "INFO"
    case .error:
      return "ERROR"
    case .fault:
      return "FAULT"
    default:
      return "WARNING"
    }
  }
  
  private class func log(_ level: OSLogType, _ tag: String, _ message: String) {
    let tag = trimTag(tag)

    #if !targetEnvironment(simulator) && !DEBUG
    let timestamp = dateFormatter.string(from: Date())
    if level != .debug {
      let formattedMsg = "[\(levelToString(level))] \(timestamp) \(tag): \(message)"
      Crashlytics.crashlytics().log("\(formattedMsg)")
    }
    #endif

    os_log("%{public}@: %{public}@", type: level, tag, message)
  }

  /** For objc compatibility only. */
  @objc class func log(_ message: String) {
    log(.default, "", message)
  }

  class func debug(_ tag: String, _ message: String) {
    log(.debug, tag, message)
  }
  
  class func info(_ tag: String, _ message: String) {
    log(.info, tag, message)
  }
  
  class func warn(_ tag: String, _ message: String) {
    log(.default, tag, message)
  }

  class func error(_ tag: String, _ message: String) {
    log(.error, tag, message)
  }

  /**
   Fault-level messages are intended for capturing system-level or
   multi-process errors only.
   */
  class func fault(_ tag: String, _ message: String) {
    log(.fault, tag, message)
  }

  // Avoid including source paths related to the build machine/user such as
  // "/Users/<username>/<local-path>/.../Simplified"
  private class func trimTag(_ tag: String) -> String {
    guard tag.starts(with: "/") else {
      return tag
    }

    var components = tag.components(separatedBy: "/")

    // remove any local path components before the source root in repo
    let sourcesRootIndex = (components.firstIndex(of: "Simplified") ?? 0) + 1

    if sourcesRootIndex < components.count {
      components.removeFirst(sourcesRootIndex)
    }

    guard !components.isEmpty else {
      return tag
    }

    return components.joined(separator: "/")
  }
}
