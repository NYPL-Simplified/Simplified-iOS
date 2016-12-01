//import Alamofire
//import Foundation
//
//// This class encapsulates analytic events sent to the server. 
//final class NYPLCirculationAnalytics : NSObject {
//  
//  class func postEvent(_ event: String, withBook book: NYPLBook) -> Void {
//    
//    if book.analyticsURL != nil{
//      let requestURL = book.analyticsURL.appendingPathComponent(event)
//    
//      Alamofire.request(.GET, requestURL, headers: self.headers).response {
//        (request, response, data, error)  in
//      
//        if (error != nil) || (response?.statusCode != 200) {
//          // Error posting event
//        }
//      
//      }
//    }
//  }
//  
//  // Server currently not validating authentication in header, but including
//  // with call in case that changes in the future
//  fileprivate class var headers:[String:String] {
//    let authenticationString = "\(NYPLAccount.shared().barcode):\(NYPLAccount.shared().pin)"
//    let authenticationData = authenticationString.data(using: String.Encoding.ascii)
//    let authenticationValue = "Basic \(authenticationData?.base64EncodedString(options: NSData.Base64EncodingOptions.lineLength64Characters)))"
//    
//    let headers = [
//      "Authorization": "\(authenticationValue)"
//    ]
//    
//    return headers
//  }
//  
//}
