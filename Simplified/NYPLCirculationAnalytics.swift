import Alamofire
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
/// and keeps a local queue of failed attempts to update them
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
    // iOS 8 not supported by Alamofire 4
    if floor(NSFoundationVersionNumber) < NSFoundationVersionNumber_iOS_9_0 {
      return;
    }
    
    Alamofire.request(url,
                      method: .get,
                      parameters: nil,
                      encoding: JSONEncoding.default,
                      headers: nil).responseData { response in
                        
                        if response.result.isSuccess {
                          self.retryOfflineAnalyticsQueueRequests()
                        } else {
                          guard let error = response.result.error as? NSError else { return }
                          if offlineQueueStatusCodes.contains(error.code) {
                            self.addToOfflineAnalyticsQueue(event, url)
                            print("Analytic Event Added to OfflineQueue. Response Error: \(response.result.error?.localizedDescription)")
                          }
                        }
                      }
  }
  
  class func retryOfflineAnalyticsQueueRequests() -> Void
  {
    let queue = NYPLSettings.shared().offlineQueue as! [[String]]
    NYPLSettings.shared().offlineQueue = nil
    
    if !queue.isEmpty {
      for queuedEvent in queue {
        post(queuedEvent[0], withURL: URL.init(string: queuedEvent[1])!)
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
