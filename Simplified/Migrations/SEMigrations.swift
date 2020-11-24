//
//  SEMigrations.swift
//  Simplified
//
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

extension NYPLMigrationManager {
  static func runMigrations() {
    // Fetch and parse app version
    let appVersion = NYPLSettings.shared.appVersion ?? ""
    let appVersionTokens = appVersion.split(separator: ".").compactMap({ Int($0) })

    // Run through migration stages
    if version(appVersionTokens, isLessThan: [3, 2, 0]) { // v3.2.0
      migrate1();
    }
    if version(appVersionTokens, isLessThan: [3, 3, 0]) { // v3.3.0
      migrate2();
    }

    // Migrate Network Queue DB
    NetworkQueue.sharedInstance.migrate()
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

      guard let oldDirectoryPath = NYPLBookContentMetadataFilesHelper.directory(for: "\(accountId)") else {
        Log.error(#file, "Could not get a directory path for accountId \(accountId)")
        continue
      }
      if FileManager.default.fileExists(atPath: oldDirectoryPath.path) {
        guard let accountUuid = accountMap[accountId] else {
          Log.error(#file, "Could not find mapping from accountID \(accountId) to uuid")
          continue
        }
        guard let newDirectoryPath = NYPLBookContentMetadataFilesHelper.directory(for: accountUuid) else {
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
