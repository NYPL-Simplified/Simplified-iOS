import Foundation

/// This class encapsulates analytic events sent to the server
/// and keeps a local queue of failed attempts to retry them
/// at a later time.
@objcMembers final class NYPLCirculationAnalytics : NSObject {

  class func postEvent(_ event: String, withBook book: NYPLBook) -> Void
  {
    if let requestURL = book.analyticsURL?.appendingPathComponent(event) {
      post(event, withURL: requestURL)
    }
  }
  
  private class func post(_ event: String, withURL url: URL) -> Void
  {
    NYPLNetworkExecutor.shared.GET(url) { result in
      switch result {
      case .success(_, _):
        debugPrint(#file, "Analytics Upload: Success")
      case .failure(let err, let response):
        let error = err as NSError
        if NetworkQueue.StatusCodes.contains(error.code) {
          self.addToOfflineAnalyticsQueue(event, url)
        }
        NYPLErrorLogger.logError(error,
                                 summary: "Circulation analytics error",
                                 metadata: [
                                  "response": response ?? "",
                                  "event": event,
                                  "url": url])
      }
    }
  }
  
  private class func addToOfflineAnalyticsQueue(_ event: String, _ bookURL: URL) -> Void
  {
    let libraryID = AccountsManager.shared.currentAccount?.uuid ?? ""
    NetworkQueue.shared.addRequest(libraryID, nil, bookURL, .GET, nil)
  }
}
