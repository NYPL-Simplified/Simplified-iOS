import Foundation

class MigrationManager: NSObject {
  @objc static func migrate() {
    // Fetch target version
    let targetVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String

    // Fetch and parse app version
    let appVersion = NYPLSettings.shared().appVersion ?? ""
    let appVersionTokens = appVersion.filter({ $0.isNumber || $0 == "." }).split(separator: ".").map({ Int($0)! })
    
    // Run through migration stages
    if versionComparator(appVersionTokens, [3, 2, 0]) { // v3.2.0
      migrate1();
    }

    // Migrate Network Queue DB
    NetworkQueue.sharedInstance.migrate()

    // Update app version
    NYPLSettings.shared().appVersion = targetVersion
  }

  private static func versionComparator(_ a: [Int], _ b:[Int]) -> Bool {
    var i = 0
    while i < a.count && i < b.count {
      if (a[i] < b[i]) {
        return true
      }
      i += 1
    }
    return a.count < b.count && b[i] > 0
  }

  // v3.2.0
  private static func migrate1() -> Void {
    // Build account map
    var accountMap = [Int: String]()
    if let accountsUrl = Bundle.main.url(forResource: "Accounts", withExtension: "json") {
      do {
        let accountsData = try Data(contentsOf: accountsUrl)
        let accountsDataObj = try JSONSerialization.jsonObject(with: accountsData, options: .allowFragments)
        if let accountsDataArray = accountsDataObj as? [[String: AnyObject]] {
          for jsonDict in accountsDataArray {
            if let numericIdNullable = jsonDict["id_numeric"] {
              let numericId = numericIdNullable as! Int
              if let uuid = jsonDict["id_uuid"] {
                accountMap[numericId] = (uuid as! String)
              }
            }
          }
        }
      } catch {
        Log.error(#file, "Accounts.json was invalid. Error: \(error.localizedDescription)")
      }
    } else {
      Log.error(#file, "Accounts.json doesn't exist!")
    }

    // Migrate user defaults
    var oldAccountsList = [Int]()
    if let libraryAccounts = NYPLSettings.shared().settingsAccountsList {
      var newLibraryAccountsList = [String]()
      for account in libraryAccounts
      {
        if let accountString = account as? String {
          newLibraryAccountsList.append(accountString)
        } else if let accountId = account as? Int {
          if let accountUuid = accountMap[accountId] {
            oldAccountsList.append(accountId)
            newLibraryAccountsList.append(accountUuid)
          }
        }
      }
      NYPLSettings.shared().settingsAccountsList = newLibraryAccountsList
    }

    // Migrate file storage
    for accountId in oldAccountsList {
      if accountId == 0 {
        continue
      }
      
      guard let oldDirectoryPath = DirectoryManager.directory("\(accountId)") else {
        Log.error(#file, "Could not get a directory path for accountId \(accountId)")
        continue
      }
      if FileManager.default.fileExists(atPath: oldDirectoryPath.path) {
        guard let accountUuid = accountMap[accountId] else {
          Log.error(#file, "Could not find mapping from accountID \(accountId) to uuid")
          continue
        }
        guard let newDirectoryPath = DirectoryManager.directory(accountUuid) else {
          Log.error(#file, "Could not get a directory path for accountUuid \(accountUuid)")
          continue
        }
        do {
          try FileManager.default.moveItem(atPath: oldDirectoryPath.path, toPath: newDirectoryPath.path)
        } catch {
          Log.error(#file, "Could not move directory from \(oldDirectoryPath.path) to \(newDirectoryPath.path) \(error)")
        }
      }
    }
  }
}
