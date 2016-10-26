import Alamofire
import Foundation

// This class encapsulates analytic events sent to the server. 
final class NYPLCirculationAnalytics : NSObject {
  
  class func postEvent(event: String, withBook book: NYPLBook) -> Void {
    

    let requestURL = book.analyticsURL.URLByAppendingPathComponent(event)
    
    Alamofire.request(.GET, requestURL, headers: self.headers).response {
       (request, response, data, error)  in
      
      if (error != nil) || (response?.statusCode != 200) {
        // Error posting event
      }
      
    }
  }
  
  // Server currently not validating authentication in header, but including
  // with call in case that changes in the future
  private class var headers:[String:String] {
    let authenticationString = "\(NYPLAccount.sharedAccount().barcode):\(NYPLAccount.sharedAccount().PIN)"
    let authenticationData = authenticationString.dataUsingEncoding(NSASCIIStringEncoding)
    let authenticationValue = "Basic \(authenticationData?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)))"
    
    let headers = [
      "Authorization": "\(authenticationValue)"
    ]
    
    return headers
  }
  
}
