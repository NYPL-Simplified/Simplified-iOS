import Foundation
import SQLite

final class NetworkQueue: NSObject {
  
  static let StatusCodes = [NSURLErrorTimedOut,
                     NSURLErrorCannotFindHost,
                     NSURLErrorCannotConnectToHost,
                     NSURLErrorNetworkConnectionLost,
                     NSURLErrorNotConnectedToInternet,
                     NSURLErrorInternationalRoamingOff,
                     NSURLErrorCallIsActive,
                     NSURLErrorDataNotAllowed,
                     NSURLErrorSecureConnectionFailed]
  static let MaxRetriesInQueue = 5
  
  enum HTTPMethodType: String {
    case GET, POST, HEAD, PUT, DELETE, OPTIONS, CONNECT
  }
  
  private static let path = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!
  
  private static let sqlTable = Table("offline_queue")
  
  private static let sqlID = Expression<Int>("id")
  private static let sqlLibraryID = Expression<Int>("library_identifier")
  private static let sqlUpdateID = Expression<String?>("update_identifier")
  private static let sqlUrl = Expression<String>("request_url")
  private static let sqlMethod = Expression<String>("request_method")
  private static let sqlParameters = Expression<Data?>("request_parameters")
  private static let sqlHeader = Expression<Data?>("request_header")
  private static let sqlRetries = Expression<Int>("retry_count")
  private static let sqlDateCreated = Expression<Data>("date_created")
  
  
  // MARK: - Public Functions
  
  class func addRequest(_ libraryID: Int,
                        _ updateID: String?,
                        _ requestUrl: URL,
                        _ method: HTTPMethodType,
                        _ parameters: Data?,
                        _ headers: [String : String]?) -> Void
  {
    // Serialize Data
    let urlString = requestUrl.absoluteString
    let methodString = method.rawValue
    let dateCreated = NSKeyedArchiver.archivedData(withRootObject: Date())
    
    let headerData: Data?
    if headers != nil {
      headerData = NSKeyedArchiver.archivedData(withRootObject: headers!)
    } else {
      headerData = nil
    }
    
    guard let db = startDatabaseConnection() else { return }
    
    // Get or create table
    do {
      try db.run(sqlTable.create(ifNotExists: true) { t in
        t.column(sqlID, primaryKey: true)
        t.column(sqlLibraryID)
        t.column(sqlUpdateID)
        t.column(sqlUrl)
        t.column(sqlMethod)
        t.column(sqlParameters)
        t.column(sqlHeader)
        t.column(sqlRetries)
        t.column(sqlDateCreated)
      })
    } catch {
      Log.error(#file, "SQLite Error: Could not create table")
      return
    }
    
    // Update (not insert) if uniqueID and libraryID match existing row in table
    let query = sqlTable.filter(sqlLibraryID == libraryID && sqlUpdateID == updateID)
                        .filter(sqlUpdateID != nil)
    
    do {
      //Try to update row
      let result = try db.run(query.update(sqlParameters <- parameters, sqlHeader <- headerData))
      if result > 0 {
        Log.debug(#file, "SQLite: Row Updated")
      } else {
        //Insert new row
        try db.run(sqlTable.insert(sqlLibraryID <- libraryID, sqlUpdateID <- updateID, sqlUrl <- urlString, sqlMethod <- methodString, sqlParameters <- parameters, sqlHeader <- headerData, sqlRetries <- 0, sqlDateCreated <- dateCreated))
        Log.debug(#file, "SQLite: Row Added")
      }
    } catch {
      Log.error(#file, "SQLite Error: Could not insert or update row")
    }
  }
  
  class func retryQueue()
  {
    guard let db = startDatabaseConnection() else { return }
    
    do {
      for row in try db.prepare(sqlTable) {
        self.retry(db: db, requestRow: row)
      }
    } catch {
      Log.error(#file, "SQLite Error accessing table or no events to retry")
    }
  }
  
  
  // MARK: - Private Functions
  
  private class func retry(db: Connection, requestRow: Row)
  {
    if (Int(requestRow[sqlRetries]) > MaxRetriesInQueue) {
      deleteRow(db: db, id: Int(requestRow[sqlID]))
      Log.info(#file, "Removing from queue after \(Int(requestRow[sqlRetries])) retries")
      return
    }
    
    do {
      let ID = Int(requestRow[sqlID])
      let newValue = Int(requestRow[sqlRetries]) + 1
      try db.run(sqlTable.filter(sqlID == ID).update(sqlRetries <- newValue))
    } catch {
      Log.error(#file, "SQLite Error incrementing retry count")
    }
    
    // Re-attempt network request
    var urlRequest = URLRequest(url: URL(string: requestRow[sqlUrl])!)
    urlRequest.httpMethod = requestRow[sqlMethod]
    urlRequest.httpBody = requestRow[sqlParameters]
    
    if let headerData = requestRow[sqlHeader],
       let headers = NSKeyedUnarchiver.unarchiveObject(with: headerData) as? [String:String] {
      for (headerKey, headerValue) in headers {
        urlRequest.setValue(headerValue, forHTTPHeaderField: headerKey)
      }
    }
    
    let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
      if let response = response as? HTTPURLResponse {
        if response.statusCode == 200 {
          Log.info(#file, "Queued Request Upload: Success")
          self.deleteRow(db: db, id: requestRow[sqlID])
        }
      }
    }
    task.resume()
  }
  
  private class func deleteRow(db: Connection, id: Int)
  {
    let rowToDelete = sqlTable.filter(sqlID == id)
    if let _ = try? db.run(rowToDelete.delete()) {
      Log.info(#file, "SQLite: deleted row from queue")
    } else {
      Log.error(#file, "SQLite Error: Could not delete row")
    }
  }
  
  private class func startDatabaseConnection() -> Connection?
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
