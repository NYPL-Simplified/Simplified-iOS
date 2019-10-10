import Foundation

/**
Manages data migrations as they are needed throughout the app's life

App version is cached in UserDefaults and last cached value is checked against current build version
and updates are applied as required

NetworkQueue migration is invoked from here, but the logic is self-contained in the NetworkQueue class.
This is because DB-related operations should likely be scoped to that file in the event the DB framework or logic changes,
that module would know best how to handle changes.
*/
class OEMigrationManager: NSObject {
  @objc static func migrate() {
    // Fetch target version
    let targetVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String

    // Fetch and parse app version
    let appVersion = NYPLSettings.shared.appVersion ?? ""
    let appVersionTokens = appVersion.split(separator: ".").compactMap({ Int($0) })
    
    // Run through migration stages
    if versionIsLessThan(appVersionTokens, [1, 7, 7]) { // v1.7.7
      migrate1();
    }

    // Migrate Network Queue DB
    NetworkQueue.sharedInstance.migrate()

    // Update app version
    //NYPLSettings.shared.appVersion = targetVersion
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

  // v1.7.7
  // Account IDs are changing, so we need to migrate resources accordingly
  private static func migrate1() -> Void {
    Log.info(#file, "Running 1.7.7 migration")
    
    // Translate account to Simplified
    AccountsManager.shared.loadCatalogs(options: .preferCache) { (success) in
      AccountsManager.shared.currentAccount = AccountsManager.shared.account(OEConfiguration.OpenEBooksUUID)
    }
  }
}
