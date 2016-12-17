import Alamofire
import Foundation

/// Singleton to handle network changes and respond
/// by performing any needed actions once internet returns.
class Reachability : NSObject {
  
  static let beginListeningForReachabilityChanges = Reachability()
  
  private override init() {
  
    let reachabilityManager = Alamofire.NetworkReachabilityManager(host: "www.apple.com")
    
    reachabilityManager?.listener = { status in
      
      switch status {
        
      case .notReachable:
        break;
        
      case .reachable(_), .unknown:
        print("Attempting to retry offline queues. Status: \(status)")
        NYPLAnnotations.retryOfflineAnnotationQueueRequests()
        NYPLCirculationAnalytics.retryOfflineAnalyticsQueueRequests()
      }
    }
    
    reachabilityManager?.startListening()
  }
}
