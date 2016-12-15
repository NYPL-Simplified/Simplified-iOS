import Alamofire
import Foundation

let offlineQueueStatusCodes = [NSURLErrorTimedOut,
                               NSURLErrorCannotFindHost,
                               NSURLErrorCannotConnectToHost,
                               NSURLErrorNetworkConnectionLost,
                               NSURLErrorNotConnectedToInternet,
                               NSURLErrorInternationalRoamingOff,
                               NSURLErrorCallIsActive,
                               NSURLErrorDataNotAllowed,
                               NSURLErrorSecureConnectionFailed]

// This class encapsulates analytic events sent to the server.
final class NYPLCirculationAnalytics : NSObject {

  class func postEvent(_ event: String, withBook book: NYPLBook) -> Void {
    
    //Cannot make AF 4.0 request in iOS8
    if floor(NSFoundationVersionNumber) < NSFoundationVersionNumber_iOS_9_0 {
      return;
    }
    
    if book.analyticsURL != nil{
      let requestURL = book.analyticsURL.appendingPathComponent(event)
      post(event, withURL: requestURL)
    }
  }
  
  
  fileprivate class func post(_ event: String, withURL url: URL) -> Void {
    
    Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil).responseData { response in
      
      let statusCode = response.response?.statusCode
      
      if response.result.isSuccess {
        
        if statusCode == 200 {
          print("open book event successfuly posted")
        }
        
        let queue = NYPLSettings.shared().offlineQueue as! [[String]]
        NYPLSettings.shared().offlineQueue = nil
        if !queue.isEmpty {
          //Retry any in Queue
          for queuedEvent in queue {
            post(queuedEvent[0], withURL: URL.init(string: queuedEvent[1])!)
          }
        }

      }
      else {
        guard let error = response.result.error as? NSError else { return }
        if offlineQueueStatusCodes.contains(error.code) {
          self.addToOfflineQueue(event, url)
          print("open book event added to offline queue. reason: \(response.result.error?.localizedDescription)")
        }
      }
    }
  }
  
  fileprivate class func addToOfflineQueue(_ event: String, _ bookURL: URL) -> Void {
    
    let newRow = [event, bookURL.absoluteString]
    var queue = NYPLSettings.shared().offlineQueue as! [[String]]
    queue.append(newRow)
    NYPLSettings.shared().offlineQueue = queue
  }
}
