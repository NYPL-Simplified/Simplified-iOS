import Foundation

let MaxOfflineQueueSize = 30

let offlineQueueStatusCodes = [NSURLErrorTimedOut,
                               NSURLErrorCannotFindHost,
                               NSURLErrorCannotConnectToHost,
                               NSURLErrorNetworkConnectionLost,
                               NSURLErrorNotConnectedToInternet,
                               NSURLErrorInternationalRoamingOff,
                               NSURLErrorCallIsActive,
                               NSURLErrorDataNotAllowed,
                               NSURLErrorSecureConnectionFailed]

/// This class encapsulates analytic events sent to the server
/// and keeps a local queue of failed attempts to retry them
/// at a later time.
final class NYPLCirculationAnalytics : NSObject {

  class func postEvent(_ event: String, withBook book: NYPLBook) -> Void
  {
    if book.analyticsURL != nil{
      let requestURL = book.analyticsURL.appendingPathComponent(event)
      post(event, withURL: requestURL)
    }
  }
  
  private class func post(_ event: String, withURL url: URL) -> Void
  {
    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    let dataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
      
      let response = response as? HTTPURLResponse
      if (error == nil && response?.statusCode == 200) {
        self.retryOfflineAnalyticsQueueRequests()
//        print("upload success")
      } else {
        guard let error = error as? NSError else { return }
        if offlineQueueStatusCodes.contains(error.code) {
          self.addToOfflineAnalyticsQueue(event, url)
          print("Analytics Upload Queued. Response Error: \(error.localizedDescription)")
        }
      }
    }
    dataTask.resume()
  }
  
  class func retryOfflineAnalyticsQueueRequests() -> Void
  {
    if let queue = NYPLSettings.shared().offlineQueue as? [[String]] {
      NYPLSettings.shared().offlineQueue = nil
      if !queue.isEmpty {
        for queuedEvent in queue {
          post(queuedEvent[0], withURL: URL.init(string: queuedEvent[1])!)
        }
      }
    }
  }
  
  private class func addToOfflineAnalyticsQueue(_ event: String, _ bookURL: URL) -> Void
  {
    let newRow = [event, bookURL.absoluteString]
    var queue = NYPLSettings.shared().offlineQueue as! [[String]]
    while queue.count >= MaxOfflineQueueSize {
      queue.remove(at: 0)
    }
    queue.append(newRow)
    NYPLSettings.shared().offlineQueue = queue
  }
}
