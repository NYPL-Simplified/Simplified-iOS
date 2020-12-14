import Foundation

/// This class encapsulates analytic events sent to the server
/// and keeps a local queue of failed attempts to retry them
/// at a later time.
@objcMembers final class NYPLCirculationAnalytics : NSObject {

  class func postEvent(_ event: String, withBook book: NYPLBook) -> Void
  {
    if book.analyticsURL != nil,
      let requestURL = book.analyticsURL?.appendingPathComponent(event) {

      post(event, withURL: requestURL)
    }
  }
  
  private class func post(_ event: String, withURL url: URL) -> Void
  {
    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    let dataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
      
      if let response = response as? HTTPURLResponse {
        if response.statusCode == 200 {
          debugPrint(#file, "Analytics Upload: Success")
        }
      } else {
        guard let error = error as NSError? else { return }
        if NetworkQueue.StatusCodes.contains(error.code) {
          self.addToOfflineAnalyticsQueue(event, url)
        }
        Log.error(#file, "URLRequest Error: \(error.code). Description: \(error.localizedDescription)")
      }
    }
    dataTask.resume()
  }
  
  private class func addToOfflineAnalyticsQueue(_ event: String, _ bookURL: URL) -> Void
  {
    let libraryID = AccountsManager.shared.currentAccount?.uuid ?? ""
    NetworkQueue.shared().addRequest(libraryID, nil, bookURL, .GET, nil, NYPLAnnotations.headers)
  }
}
