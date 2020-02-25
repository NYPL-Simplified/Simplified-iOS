import Foundation

/// Returns the URL of the directory used for storing content and metadata.
/// The directory is not guaranteed to exist at the time this method is called.
@objcMembers final class DirectoryManager : NSObject {
  
  class func current() -> URL? {
    guard let account = AccountsManager.shared.currentAccount else {
      NYPLBugsnagLogs.report(NSError(domain:"org.nypl.labs.SimplyE", code:11, userInfo:nil),
                             groupingHash: "unexpected-nil-account",
                             context: "DirectoryManager::current")
      return nil
    }
    return directory(account.uuid)
  }
  
  class func directory(_ account: String) -> URL? {
    let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
    
    if paths.count < 1 {
      NYPLBugsnagLogs.report(NSError(domain:"org.nypl.labs.SimplyE", code:12, userInfo:nil),
                             with: "No valid paths",
                             groupingHash: "directory-manager")
      return nil
    } else if paths.count > 1 {
      NYPLBugsnagLogs.report(NSError(domain:"org.nypl.labs.SimplyE", code:12, userInfo:nil),
                             with: "Multiple paths",
                             severity: .warning,
                             groupingHash: "directory-manager")
    }
    
    var directoryURL = URL.init(fileURLWithPath: paths[0]).appendingPathComponent(Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as! String)
    
    if (account != AccountsManager.NYPLAccountUUIDs[0]) {
      directoryURL = URL.init(fileURLWithPath: paths[0]).appendingPathComponent(Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as! String).appendingPathComponent(String(account))
    }
    return directoryURL
  }
}
