import Foundation

/**
Manages data migrations as they are needed throughout the app's life

App version is cached in UserDefaults and last cached value is checked against current build version
and updates are applied as required

NetworkQueue migration is invoked from here, but the logic is self-contained in the NetworkQueue class.
This is because DB-related operations should likely be scoped to that file in the event the DB framework or logic changes,
that module would know best how to handle changes.
*/ 
class NYPLMigrationManager: NSObject {
  @objc static func migrate() {
    // Fetch target version
    let targetVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String

    runMigrations()

    // Update app version
    NYPLSettings.shared.appVersion = targetVersion
  }

  // Less-than comparator operation
  static func versionIsLessThan(_ a: [Int], _ b:[Int]) -> Bool {
    var i = 0
    while i < a.count && i < b.count {
      guard a[i] == b[i] else {
        return a[i] < b[i]
      }

      i += 1
    }

    // e.g.: 1.1 < 1.1.x
    return a.count < b.count && b[i] > 0
  }
}
