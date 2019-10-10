import Foundation

/**
Manages data migrations as they are needed throughout the app's life

App version is cached in UserDefaults and last cached value is checked against current build version
and updates are applied as required

NetworkQueue migration is invoked from here, but the logic is self-contained in the NetworkQueue class.
This is because DB-related operations should likely be scoped to that file in the event the DB framework or logic changes,
that module would know best how to handle changes.
*/ 
class SEMigrationManager: NSObject {
  @objc static func migrate() {
    // Fetch target version
    let targetVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String

    // Fetch and parse app version
    let appVersion = NYPLSettings.shared.appVersion ?? ""
    let appVersionTokens = appVersion.split(separator: ".").compactMap({ Int($0) })
    
    // Run through migration stages
    if versionIsLessThan(appVersionTokens, [3, 2, 0]) { // v3.2.0
      migrate1();
    }
    if versionIsLessThan(appVersionTokens, [3, 3, 0]) { // v3.3.0
      migrate2();
    }

    // Migrate Network Queue DB
    NetworkQueue.sharedInstance.migrate()

    // Update app version
    NYPLSettings.shared.appVersion = targetVersion
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
  // Account IDs are changing, so we need to migrate resources accordingly
  private static func migrate1() -> Void {
    Log.info(#file, "Running 3.2.0 migration")
    
    // Build account map where the key is the old account ID and the value is the new account ID
    // This will help us perform the rest of the migrations logic
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

    // Build old & new lists for reference in logic
    // Note: Can't use NYPLSettings because the swift version stops using optionals and performs coerscions
    let oldAccountsList = UserDefaults.standard.array(forKey: "NYPLSettingsLibraryAccountsKey")?.compactMap({ $0 as? Int }) ?? [Int]()
    let newAccountsList = UserDefaults.standard.array(forKey: "NYPLSettingsLibraryAccountsKey")?.compactMap({
      let idInt = $0 as? Int
      return $0 as? String ?? (idInt != nil ? accountMap[idInt!] : nil)
    }) ?? [String]()

    // Assign new uuid account list
    // The list of accounts would have been integers before; they will now be stored as a list of strings
    NYPLSettings.shared.settingsAccountsList = newAccountsList
    
    // Migrate currentAccount
    // The old account ID that's being stored in the user defaults will be replaces with the string UUID
    let userDefaults = UserDefaults.standard
    if let currentAccountIntId = userDefaults.object(forKey: currentAccountIdentifierKey) as? Int {
      userDefaults.set(accountMap[currentAccountIntId], forKey: currentAccountIdentifierKey)
    }

    // Migrate file storage
    // Some resources are based on their account IDs, which have changed from integers to UUIDs
    // This will move them from the old destination to the new one
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
  
  // v3.3.0
  // Cached library registry results locations are changing
  private static func migrate2() -> Void {
    Log.info(#file, "Running 3.3.0 migration")
    
    // Cache locations are changing for catalogs, so we'll simply remove anything at the old locations
    let applicationSupportUrl = try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    let origBetaUrl = applicationSupportUrl.appendingPathComponent("library_list_beta.json")
    let origProdUrl = applicationSupportUrl.appendingPathComponent("library_list_prod.json")
    try? FileManager.default.removeItem(at: origBetaUrl)
    try? FileManager.default.removeItem(at: origProdUrl)
    if FileManager.default.fileExists(atPath: origBetaUrl.absoluteString) {
      Log.warn(#file, "Old beta cache still exists")
    }
    if FileManager.default.fileExists(atPath: origProdUrl.absoluteString) {
      Log.warn(#file, "Old prod cache still exists")
    }
  }
}
