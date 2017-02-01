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

enum HTTPMethodType: String {
  case GET, POST, HEAD, PUT, DELETE, OPTIONS, CONNECT
}

final class NetworkQueue {
  
  private static let path = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!
  
  private static let sqlTable = Table("queueTable")
  
  static let sqlLibraryID = Expression<Int>("libraryIdentifier")
  static let sqlUpdateID = Expression<String?>("updateIdentifier")
  static let sqlUrl = Expression<String>("requestUrl")
  static let sqlMethod = Expression<String>("requestMethod")
  static let sqlParameters = Expression<Data?>("requestParameters")
  static let sqlHeader = Expression<Data?>("requestHeader")
  
  private static let sqlRetries = Expression<Int>("retryCount")
  private static let sqlLastModified = Expression<String>("lastModified")
  
  
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
        t.column(sqlLibraryID)
        t.column(sqlUpdateID)
        t.column(sqlUrl)
        t.column(sqlMethod)
        t.column(sqlParameters)
        t.column(sqlHeader)
        t.column(sqlRetries)
      })
    } catch {
      print("Error: Could not create table")
      return
    }
    
    // If ID's exist in table, row should only be updated
    let query = sqlTable.filter(sqlLibraryID == libraryID && sqlUpdateID == updateID)
    
    do {
      // Update row
      if try db.run(query.update(sqlRetries++)) > 0 {
        print("SQL Row Updated - Success")  //GODO temp
      
      // Insert new row
      } else {
        
        do {
          try db.run(sqlTable.insert(sqlLibraryID <- libraryID, sqlUpdateID <- updateID, sqlUrl <- urlString, sqlMethod <- methodString, sqlParameters <- parameters, sqlHeader <- headerData))
          print("SQL Row Added - Success")  //GODO temp
        } catch {
          print("Error: Could not update table")
        }
      }
    } catch {
      print("Error: SQLite Error. Could not update queue")
    }
  }

  class func queue() -> [Row]?
  {
    guard let db = startDatabaseConnection() else { return nil }
    
    var array = [Row]()
    do {
      array = Array(try db.prepare(sqlTable))
      return array
    } catch {
      print("Error: could not retrieve array")
      return nil
    }
  }
  
  private class func retry(request: Row)
  {  
    var urlRequest = URLRequest(url: URL(string: request[sqlUrl])!)
    urlRequest.httpMethod = request[sqlMethod]
    urlRequest.httpBody = request[sqlParameters]
    
    let headerDict = NSKeyedUnarchiver.unarchiveObject(with: request[sqlHeader]!) as? [String:String]
    
    if let headers = headerDict {
      for (headerKey, headerValue) in headers {
        urlRequest.setValue(headerValue, forHTTPHeaderField: headerKey)
      }
    }
    
    let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
      
      guard let response = response as? HTTPURLResponse else { return }
      if response.statusCode == 200 {
          print("Post Last-Read: Success")
      } else {
        guard let error = error as? NSError else { return }
        if OfflineQueueStatusCodes.contains(error.code) {
          //Re-Add Request
          print("Last Read Position Added to OfflineQueue. Response Error: \(error.localizedDescription)")
        }
      }
    }
    task.resume()
  }
  
  class func row(id: Int) -> Row?
  {
    guard let db = startDatabaseConnection() else { return nil }
    
    let query = sqlTable.filter(rowid == Int64(id))
    if let row = try? db.pluck(query) {
      return row
    } else {
      return nil
    }
  }
  
  class func deleteRow(id: Int)
  {
    guard let db = startDatabaseConnection() else { return }
    
    let rowToDelete = sqlTable.filter(rowid == Int64(id))
    if let _ = try? db.run(rowToDelete.delete()) {
      print("Successfully deleted row")         //GODO temp
    } else {
      print("Error: Could not delete row")
    }
  }
  
  
  // MARK: - Private Functions
  
  private class func startDatabaseConnection() -> Connection?
  {
    let db: Connection
    do {
      db = try Connection("\(path)/db.sqlite3")
    } catch {
      print("Could not open sqlite db connection.")
      return nil
    }
    return db
  }
}
