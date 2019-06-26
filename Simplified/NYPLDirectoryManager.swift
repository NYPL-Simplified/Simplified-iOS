import Foundation
import Bugsnag

/// Returns the URL of the directory used for storing content and metadata.
/// The directory is not guaranteed to exist at the time this method is called.
@objcMembers final class DirectoryManager : NSObject {
  
  class func current() -> URL? {
    guard let account = AccountsManager.shared.currentAccount else {
      Bugsnag.notifyError(NSError(domain:"org.nypl.labs.SimplyE", code:11, userInfo:nil)) { report in
        report.groupingHash = "unexpected-nil-account"
        report.context = "DirectoryManager::current"
      }
      return nil
    }
    return directory(account.uuid)
  }
  
  class func directory(_ account: String) -> URL? {
    let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
    
    if paths.count < 1 {
      Bugsnag.notifyError(NSError(domain:"org.nypl.labs.SimplyE", code:12, userInfo:nil)) { report in
        report.groupingHash = "directory-manager"
        report.errorMessage = "No valid paths"
      }
      return nil
    } else if paths.count > 1 {
      Bugsnag.notifyError(NSError(domain:"org.nypl.labs.SimplyE", code:12, userInfo:nil)) { report in
        report.groupingHash = "directory-manager"
        report.errorMessage = "Multiple paths"
        report.severity = BSGSeverity.warning
      }
    }
    
    var directoryURL = URL.init(fileURLWithPath: paths[0]).appendingPathComponent(Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as! String)
    
    if (account != AccountsManager.NYPLAccountUUIDs[0]) {
      directoryURL = URL.init(fileURLWithPath: paths[0]).appendingPathComponent(Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as! String).appendingPathComponent(String(account))
    }
    return directoryURL
  }
}
