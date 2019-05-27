import Foundation

/**
Manages data migrations as they are needed throughout the app's life

App version is cached in UserDefaults and last cached value is checked against current build version
and updates are applied as required
*/ 
class MigrationManager: NSObject {
  @objc static func migrate() {
    // Fetch target version
    let targetVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String

    // Fetch and parse app version
    let appVersion = NYPLSettings.shared().appVersion ?? ""
    let appVersionTokens = appVersion.split(separator: ".").compactMap({ Int($0) })
    
    // Run through migration stages
    if versionIsLessThan(appVersionTokens, [3, 2, 0]) { // v3.2.0
      migrate1();
    }

    // Migrate Network Queue DB
    NetworkQueue.sharedInstance.migrate()

    // Update app version
    NYPLSettings.shared().appVersion = targetVersion
  }

  // Less-than comparator operation
  private static func versionIsLessThan(_ a: [Int], _ b:[Int]) -> Bool {
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
            if let numericId = jsonDict["id_numeric"] as? Int, let uuid = jsonDict["id_uuid"] as? String {
              accountMap[numericId] = uuid
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
    let oldAccountsList = NYPLSettings.shared().settingsAccountsList?.compactMap({ $0 as? Int }) ?? [Int]()
    let newAccountsList = NYPLSettings.shared().settingsAccountsList?.compactMap({
      let idInt = $0 as? Int
      return $0 as? String ?? (idInt != nil ? accountMap[idInt!] : nil)
    }) ?? [String]()

    // Assign new uuid account list
    NYPLSettings.shared().settingsAccountsList = newAccountsList
    
    // Migrate currentAccount
    let userDefaults = UserDefaults.standard
    if let currentAccountIntId = userDefaults.object(forKey: currentAccountIdentifierKey) as? Int {
      userDefaults.set(accountMap[currentAccountIntId], forKey: currentAccountIdentifierKey)
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
