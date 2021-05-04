import Foundation

/// Returns the URL of the directory used for storing content and metadata.
/// The directory is not guaranteed to exist at the time this method is called.
@objcMembers final class NYPLBookContentMetadataFilesHelper : NSObject {
  
  class func currentAccountDirectory() -> URL? {
    guard let account = AccountsManager.shared.currentAccount else {
      return nil
    }
    return directory(for: account.uuid)
  }
  
  class func directory(for account: String) -> URL? {
    let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
    
    if paths.count < 1 {
      NYPLErrorLogger.logError(withCode: .missingSystemPaths,
                               summary: "No valid search paths in iOS's ApplicationSupport directory in UserDomain",
                               metadata: ["account": account])
      return nil
    }

    let bundleID = Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as! String
    var dirURL = URL(fileURLWithPath: paths[0]).appendingPathComponent(bundleID)
    
    if (account != AccountsManager.shared.NYPLAccountUUID) {
      dirURL = dirURL.appendingPathComponent(String(account))
    }
    
    return dirURL
  }
}
