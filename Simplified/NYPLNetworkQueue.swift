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
  
  private static let sqlTable = Table("queueTable")
  
  private static let sqlID = Expression<Int>("rowid")
  private static let sqlLibraryID = Expression<Int>("libraryIdentifier")
  private static let sqlUpdateID = Expression<String?>("updateIdentifier")
  private static let sqlUrl = Expression<String>("requestUrl")
  private static let sqlMethod = Expression<String>("requestMethod")
  private static let sqlParameters = Expression<Data?>("requestParameters")
  private static let sqlHeader = Expression<Data?>("requestHeader")
  private static let sqlRetries = Expression<Int>("retryCount")
  private static let sqlDateCreated = Expression<Data>("dateCreated")
  
  
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
      // Update row
      if try db.run(query.update(sqlParameters <- parameters, sqlHeader <- headerData)) > 0 {
        debugPrint("SQLite Row Updated - Success")
        
      // Insert new row
      } else {
        do {
          try db.run(sqlTable.insert(sqlLibraryID <- libraryID, sqlUpdateID <- updateID, sqlUrl <- urlString, sqlMethod <- methodString, sqlParameters <- parameters, sqlHeader <- headerData, sqlRetries <- 0, sqlDateCreated <- dateCreated))
          debugPrint(#file, "SQLite Row Added - Success")
        } catch {
          Log.error(#file, "SQLite Error: Could not update table")
        }
      }
    } catch {
      Log.error(#file, "SQLite Error: Could not update queue")
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
      debugPrint(#file, "Removing after \(Int(requestRow[sqlRetries])) retries")
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
          self.deleteRow(db: db, id: requestRow[sqlID])
          debugPrint(#file, "Successfully Completed Queued Request")
        }
      }
    }
    task.resume()
  }
  
  private class func deleteRow(db: Connection, id: Int)
  {
    let rowToDelete = sqlTable.filter(sqlID == id)
    if let _ = try? db.run(rowToDelete.delete()) {
      debugPrint(#file, "SQLite deleted row from queue")
    } else {
      Log.error(#file, "SQLite Error: Could not delete row")
    }
  }
  
  private class func startDatabaseConnection() -> Connection?
  {
    let db: Connection
    do {
      db = try Connection("\(path)/db.sqlite3")
    } catch {
      Log.error(#file, "Could not open SQLite db connection.")
      return nil
    }
    return db
  }
}
