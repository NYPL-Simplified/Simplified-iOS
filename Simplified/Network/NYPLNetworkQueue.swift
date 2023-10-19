import Foundation
import SQLite

/**
 Recommended pattern by SQLite docs
 userVersion access allows us to migrate schemas going forward
 */
extension Connection {
  public var userVersion: Int {
    get { return Int(try! scalar("PRAGMA user_version") as! Int64) }
    set { try! run("PRAGMA user_version = \(newValue)") }
  }
}

/**
 The NetworkQueue is insantiated once on app startup and listens
 for a valid network notification from a reachability class. It then
 will retry any queued requests and purge them if necessary.
 */
final class NetworkQueue: NSObject {

  @objc static let shared = NetworkQueue()

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  static let StatusCodes = [NSURLErrorTimedOut,
                            NSURLErrorCannotFindHost,
                            NSURLErrorCannotConnectToHost,
                            NSURLErrorNetworkConnectionLost,
                            NSURLErrorNotConnectedToInternet,
                            NSURLErrorInternationalRoamingOff,
                            NSURLErrorCallIsActive,
                            NSURLErrorDataNotAllowed,
                            NSURLErrorSecureConnectionFailed]
  let MaxRetriesInQueue = 5

  let serialQueue = DispatchQueue(label: Bundle.main.bundleIdentifier!
                                  + "."
                                  + String(describing: NetworkQueue.self))

  private static let DBVersion = 1
  private static let TableName = "offline_queue"

  enum HTTPMethodType: String {
    case GET, POST, HEAD, PUT, DELETE, OPTIONS, CONNECT
  }

  private var retryRequestCount = 0
  private let path = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!
  
  private let sqlTable = Table(NetworkQueue.TableName)
  
  private let sqlID = Expression<Int>("id")
  private let sqlLibraryID = Expression<String>("library_identifier")
  private let sqlUpdateID = Expression<String?>("update_identifier")
  private let sqlUrl = Expression<String>("request_url")
  private let sqlMethod = Expression<String>("request_method")
  private let sqlParameters = Expression<Data?>("request_parameters")
  private let sqlHeader = Expression<Data?>("request_header")
  private let sqlRetries = Expression<Int>("retry_count")
  private let sqlDateCreated = Expression<Data>("date_created")
  
  
  // MARK: - Public Functions

  @objc func addObserverForOfflineQueue() {
    NotificationCenter.default.addObserver(forName: NSNotification.Name.NYPLReachabilityHostIsReachable,
                                           object: nil,
                                           queue: nil) { notification in self.retryQueue() }
  }

  func addRequest(_ libraryID: String,
                  _ updateID: String?,
                  _ requestUrl: URL,
                  _ method: HTTPMethodType,
                  _ parameters: Data?) -> Void
  {
    self.serialQueue.async {

      // Serialize Data
      let urlString = requestUrl.absoluteString
      let methodString = method.rawValue
      let dateCreated = NSKeyedArchiver.archivedData(withRootObject: Date())
      // left for backward compatibility
      let headerData: Data? = nil

      guard let db = self.startDatabaseConnection() else { return }
      
      // Update (not insert) if uniqueID and libraryID match existing row in table
      let query = self.sqlTable.filter(self.sqlLibraryID == libraryID && self.sqlUpdateID == updateID)
        .filter(self.sqlUpdateID != nil)
      
      do {
        //Try to update row
        let result = try db.run(query.update(self.sqlParameters <- parameters, self.sqlHeader <- headerData))
        if result > 0 {
          Log.debug(#file, "SQLite: Row Updated")
        } else {
          //Insert new row
          try db.run(self.sqlTable.insert(self.sqlLibraryID <- libraryID,
                                          self.sqlUpdateID <- updateID,
                                          self.sqlUrl <- urlString,
                                          self.sqlMethod <- methodString,
                                          self.sqlParameters <- parameters,
                                          self.sqlHeader <- headerData,
                                          self.sqlRetries <- 0,
                                          self.sqlDateCreated <- dateCreated))
          Log.debug(#file, "SQLite: Row Added")
        }
      } catch {
        Log.error(#file, "SQLite Error: Could not insert or update row: \(error)")
      }
    }
  }

  func migrateOrSetUpIfNeeded()
  {
    self.serialQueue.async {
      guard let db = self.startDatabaseConnection() else {
        Log.error(#file, "Failed to start database connection for a retry attempt.")
        return
      }
      
      let tableCount = Int(try! db.scalar("SELECT count(*) FROM sqlite_master WHERE type = 'table' AND name = '\(NetworkQueue.TableName)'") as! Int64)
      if tableCount < 1 {
        self.createTable(db: db)
        db.userVersion = NetworkQueue.DBVersion
      } else {
        var dbVersion = db.userVersion
        // TODO: Consider optimizing migrations by checking if
        // there's a breaking change between current version and target version
        // If there is, we can probably immediately jump to current version,
        // invoking createTable()
        do {
          while dbVersion < NetworkQueue.DBVersion { // Iterate
            switch dbVersion {
            case 0:
              try db.run(self.sqlTable.drop(ifExists: true))
              self.createTable(db: db)
              dbVersion = NetworkQueue.DBVersion
              db.userVersion = NetworkQueue.DBVersion
            default:
              break
            }
            dbVersion += 1
          }
        } catch {
          Log.error(#file, "SQLite Error: Could not migrate.")
        }
      }
    }
  }

  // MARK: - Private Functions

  private func createTable(db: Connection)
  {
    do {
      try db.run(self.sqlTable.create(ifNotExists: true) { t in
        t.column(self.sqlID, primaryKey: true)
        t.column(self.sqlLibraryID)
        t.column(self.sqlUpdateID)
        t.column(self.sqlUrl)
        t.column(self.sqlMethod)
        t.column(self.sqlParameters)
        t.column(self.sqlHeader)
        t.column(self.sqlRetries)
        t.column(self.sqlDateCreated)
      })
    } catch {
      Log.error(#file, "SQLite Error: Could not create table")
    }
  }

  private func retryQueue()
  {
    self.serialQueue.async {

      if self.retryRequestCount > 0 {
        Log.debug(#file, "Retry requests are still in progress. Cancelling this attempt.")
        return
      }

      guard let db = self.startDatabaseConnection() else {
        Log.error(#file, "Failed to start database connection for a retry attempt.")
        return
      }

      let expiredRows = self.sqlTable.filter(self.sqlRetries > self.MaxRetriesInQueue)
      do {
        try db.run(expiredRows.delete())

        self.retryRequestCount = try db.scalar(self.sqlTable.count)
        Log.debug(#file, "Executing \"retry\" with \(self.retryRequestCount) row(s) in the table.")

        for row in try db.prepare(self.sqlTable) {
          Log.debug(#file, "Retrying row: \(row[self.sqlID])")
          self.retry(db, requestRow: row)
        }
      } catch {
        Log.error(#file, "SQLite Error: Failure to prepare table or run deletion")
      }
    }
  }

  private func retry(_ db: Connection, requestRow: Row)
  {
    do {
      let ID = Int(requestRow[sqlID])
      let newValue = Int(requestRow[sqlRetries]) + 1
      try db.run(sqlTable.filter(sqlID == ID).update(sqlRetries <- newValue))
    } catch {
      Log.error(#file, "SQLite Error incrementing retry count")
    }
    
    // Re-attempt network request
    let urlRequest = NYPLNetworkExecutor.shared
      .request(for: URL(string: requestRow[sqlUrl])!,
               httpMethod: requestRow[sqlMethod],
               httpBody: requestRow[sqlParameters])

    Log.info(#file, "Retrying request from offline queue: \(urlRequest)")
    NYPLNetworkExecutor.shared.executeRequest(urlRequest) { result in
      self.serialQueue.async { [weak self] in
        guard let self = self else { return }
        switch result {
        case .success(_, _):
          Log.info(#file, "Queued Request Upload: Success")
          self.deleteRow(db, id: requestRow[self.sqlID])
        case .failure(let error, let response):
          NYPLErrorLogger.logNetworkError(error,
                                          code: .responseFail,
                                          summary: "Error retrying request from offline queue",
                                          request: urlRequest,
                                          response: response)
        }

        self.retryRequestCount -= 1
      }
    }
  }

  private func deleteRow(_ db: Connection, id: Int)
  {
    let rowToDelete = sqlTable.filter(sqlID == id)
    if let _ = try? db.run(rowToDelete.delete()) {
      Log.info(#file, "SQLite: deleted row from queue")
    } else {
      Log.error(#file, "SQLite Error: Could not delete row")
    }
  }
  
  private func startDatabaseConnection() -> Connection?
  {
    let db: Connection
    do {
      db = try Connection("\(path)/simplified.db")
    } catch {
      Log.error(#file, "SQLite: Could not start DB connection.")
      return nil
    }
    return db
  }
}
