import Foundation
import SQLite

let OfflineQueueStatusCodes = [NSURLErrorTimedOut,
                               NSURLErrorCannotFindHost,
                               NSURLErrorCannotConnectToHost,
                               NSURLErrorNetworkConnectionLost,
                               NSURLErrorNotConnectedToInternet,
                               NSURLErrorInternationalRoamingOff,
                               NSURLErrorCallIsActive,
                               NSURLErrorDataNotAllowed,
                               NSURLErrorSecureConnectionFailed]
let MaxRetryCount = 3

enum HTTPMethodType: String {
  case GET, POST, HEAD, PUT, DELETE, OPTIONS, CONNECT
}

final class NetworkQueue: NSObject {
  
  private static let path = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!
  
  private static let sqlTable = Table("queueTable")
  
  static let sqlID = Expression<Int64>("rowid")
  static let sqlLibraryID = Expression<Int>("libraryIdentifier")
  static let sqlUpdateID = Expression<String?>("updateIdentifier")
  static let sqlUrl = Expression<String>("requestUrl")
  static let sqlMethod = Expression<String>("requestMethod")
  static let sqlParameters = Expression<Data?>("requestParameters")
  static let sqlHeader = Expression<Data?>("requestHeader")
  static let sqlRetries = Expression<Int>("retryCount")
  
  
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
      })
    } catch {
      print("SQLite Error: Could not create table")
      return
    }
    
    // Update (not insert) if uniqueID and libraryID match existing row in table
    let query = sqlTable.filter(sqlLibraryID == libraryID && sqlUpdateID == updateID)
                        .filter(sqlUpdateID != nil)
    
    do {
      // Update row
      if try db.run(query.update(sqlParameters <- parameters, sqlHeader <- headerData)) > 0 {
        print("SQLite Row Updated - Success")  //GODO temp
        
      // Insert new row
      } else {
        do {
          try db.run(sqlTable.insert(sqlLibraryID <- libraryID, sqlUpdateID <- updateID, sqlUrl <- urlString, sqlMethod <- methodString, sqlParameters <- parameters, sqlHeader <- headerData, sqlRetries <- 0))
          print("SQLite Row Added - Success")  //GODO temp
        } catch {
          print("SQLite Error: Could not update table")
        }
      }
    } catch {
      print("SQLite Error: Could not update queue")
    }
  }
  
  class func retryQueue()
  {
    guard let db = startDatabaseConnection() else { return }
    
    do {
      for row in try db.prepare(sqlTable) {
        self.retry(requestRow: row)
      }
    } catch {
      print("SQLite Error accessing table")
    }
  }
  
  
  // MARK: - Private Functions
  
  private class func retry(requestRow: Row)
  {
    if (requestRow[sqlRetries] > MaxRetryCount) {
      deleteRow(id: requestRow[sqlID])
      return
    }
    
    guard let db = startDatabaseConnection() else { return }
    do {
      //GODO can't figure out why this command is not working
      let result = try db.run(sqlTable.filter(sqlID == requestRow[sqlID]).update(sqlRetries++))
      print("SQLite (\(result)) row(s) retry count incremented.")
    } catch {
      print("SQLite Error incrementing retry count")
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
          self.deleteRow(id: requestRow[sqlID])
          print("Successfully Completed Queued Request")
        }
      }
    }
    task.resume()
  }
  
  private class func deleteRow(id: Int64)
  {
    guard let db = startDatabaseConnection() else { return }
    
    let rowToDelete = sqlTable.filter(sqlID == id)
    if let _ = try? db.run(rowToDelete.delete()) {
      print("SQLite deleted row from queue")         //GODO temp
    } else {
      print("SQLite Error: Could not delete row")
    }
  }
  
  private class func startDatabaseConnection() -> Connection?
  {
    let db: Connection
    do {
      db = try Connection("\(path)/db.sqlite3")
    } catch {
      print("Could not open SQLite db connection.")
      return nil
    }
    return db
  }
}
