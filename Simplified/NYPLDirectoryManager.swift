import Foundation

/// Returns the URL of the directory used for storing content and metadata.
/// The directory is not guaranteed to exist at the time this method is called.
@objcMembers final class DirectoryManager : NSObject {
  
  class func current() -> URL? {
    guard let account = AccountsManager.shared.currentAccount else {
      return nil
    }
    return directory(account.uuid)
  }
  
  class func directory(_ account: String) -> URL? {
    let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
    
    if paths.count < 1 {
      NYPLErrorLogger.logError(withCode: .missingSystemPaths,
                               summary: "DirectoryManager::directory",
                               message: "No valid search paths in iOS's ApplicationSupport directory in the UserDomain",
                               metadata: ["account": account])
      return nil
    }
    
    var directoryURL = URL.init(fileURLWithPath: paths[0]).appendingPathComponent(Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as! String)
    
    if (account != AccountsManager.NYPLAccountUUIDs[0]) {
      directoryURL = URL.init(fileURLWithPath: paths[0]).appendingPathComponent(Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as! String).appendingPathComponent(String(account))
    }
    return directoryURL
  }
}
