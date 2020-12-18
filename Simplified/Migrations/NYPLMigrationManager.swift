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

  /// Compares app versions.
  ///
  /// - Note: An empty `a` version is considered "less than" a non-empty `b`.
  /// 
  /// - Parameters:
  ///   - a: An array of integers expressing a version number.
  ///   - b: An array of integers expressing a version number.
  /// - Returns: `true` if version `a` is anterior to version `b`, or if `a` is
  /// empty and `b` is not, or if `a` and `b` coincide except `b` has more
  /// components than `a` (e.g. 1.2 vs 1.2.1).
  static func version(_ a: [Int], isLessThan b:[Int]) -> Bool {
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
