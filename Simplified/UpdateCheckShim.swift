import Foundation

/// This class exists to work around a compiler bug present in Xcode 7.3.1. It
/// seems it cannot handle generating interfaces for classes containing
/// structures that implement Swift protocols (e.g. `Comparable`), possibly
/// amongst many other things.
@objcMembers final class UpdateCheckShim: NSObject {
  
  /// @param minimumVersionURL An `NSURL` pointing to JSON data of the following format:
  /// {"iOS" = {"minimum-version" = "1.0.0", "update-url" = "http://example.com"}, …}
  ///
  /// @param updateNeededForURL A handler that is called on an arbitrary thread with a
  /// version string and an update URL _only_ when an update is needed.
  static func performUpdateCheckWithURL(_ minimumVersionURL: URL, handler: @escaping (String, URL) -> Void) {
    UpdateCheck.performUpdateCheck(minimumVersionURL) { (result) in
      switch result {
      case let UpdateCheck.Result.needsUpdate(minimumVersion, updateURL):
        handler("\(minimumVersion.major).\(minimumVersion.minor).\(minimumVersion.patch)", updateURL)
      default:
        break
      }
    }
  }
}
