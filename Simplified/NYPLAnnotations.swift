//
//  NNYPLAnnotations.swift
//  Simplified
//
//  Created by Aferdita Muriqi on 10/18/16.
//  Copyright © 2016 NYPL Labs. All rights reserved.
//

import UIKit
import Alamofire

final class NYPLAnnotations: NSObject {
  
  class func postLastRead(_ book:NYPLBook, cfi:NSString)
  {
    //Last Read currently disabled
//    if (NYPLAccount.shared().hasBarcodeAndPIN())
//    {
//      let parameters = [
//        "@context": "http://www.w3.org/ns/anno.jsonld",
//        "type": "Annotation",
//        "motivation": "http://librarysimplified.org/terms/annotation/idling",
//        "target":[
//          "source": book.identifier,
//          "selector": [
//            "type": "oa:FragmentSelector",
//            "value": cfi
//          ]
//        ]
//        ] as [String : Any]
//      
//      let url = NYPLConfiguration.mainFeedURL().appendingPathComponent("annotations/")
//      
//      postJSONRequest(url, parameters, NYPLAnnotations.headers)
//    }
  }
  
  class func sync(_ book:NYPLBook, completionHandler: @escaping (_ responseObject: String?, _ error: NSError?) -> ()) {
    //Sync Currently Disabled
//    syncLastRead(book, completionHandler: completionHandler)
  }
  
  private class func postJSONRequest(_ url: URL, _ parameters: [String:Any], _ headers: [String:String])
  {
    // iOS 8 not supported by Alamofire 4
//    if floor(NSFoundationVersionNumber) < NSFoundationVersionNumber_iOS_9_0 {
//      return;
//    }
//    
//    Alamofire.request(url,
//                      method: .post,
//                      parameters: parameters,
//                      encoding: JSONEncoding.default,
//                      headers: headers).responseData { response in
//                        
//                        switch(response.result) {
//                        case .success(_):
//                          if response.response?.statusCode == 200 {
//                            print("Post Last-Read: Success")
//                          }
//                        case .failure(_):
//                          guard let error = response.result.error as? NSError else { return }
//                          if offlineQueueStatusCodes.contains(error.code) {
//                            self.addToOfflineAnnotationsQueue(url, parameters, headers)
//                            print("Last Read Position Added to OfflineQueue. Response Error: \(response.result.error?.localizedDescription)")
//                          }
//                        }
//                      }
  }
  
  private class func addToOfflineAnnotationsQueue(_ url: URL, _ parameters: [String:Any], _ headers: [String:String])
  {
//    var queue = NYPLSettings.shared().annotationsOfflineQueue as! [[Any]]
//    
//    while queue.count >= MaxOfflineQueueSize {
//      queue.remove(at: 0)
//    }
//    if queue.count > 0 {
//      // Only most recent kept for each book URL
//      for i in 0..<queue.count {
//        let queueEntry = queue[i]
//        let urlString = queueEntry[0] as! String
//        if urlString == url.absoluteString {
//          queue.remove(at: i)
//          print("Replacing older offline queue entry")
//        }
//      }
//    }
//    let newRow = [url.absoluteString as Any, parameters, headers] as [Any]
//    queue.append(newRow)
//    
//    NYPLSettings.shared().annotationsOfflineQueue = queue
  }
  
  class func retryOfflineAnnotationQueueRequests() -> Void
  {
//    let queue = NYPLSettings.shared().annotationsOfflineQueue as! [[Any]]
//    NYPLSettings.shared().annotationsOfflineQueue = nil
//    
//    if !queue.isEmpty {
//      for queuedEvent in queue {
//        let url = URL.init(string: queuedEvent[0] as! String)!
//        postJSONRequest(url, queuedEvent[1] as! [String : Any], queuedEvent[2] as! [String : String])
//      }
//    }
  }
  
  private class func syncLastRead(_ book:NYPLBook, completionHandler: @escaping (_ responseObject: String?,
    _ error: NSError?) -> ()) {
    
    //Cannot make AF 4.0 request in iOS8
//    if floor(NSFoundationVersionNumber) < NSFoundationVersionNumber_iOS_9_0 {
//      return;
//    }
//    
//    if (NYPLAccount.shared().hasBarcodeAndPIN())
//    {
//      if book.annotationsURL != nil {
//        
//        Alamofire.request(book.annotationsURL.absoluteString, method: .get, parameters: ["":""], encoding: URLEncoding.default, headers: NYPLAnnotations.headers).responseJSON { (response:DataResponse<Any>) in
//          
//          switch(response.result) {
//          case .success(_):
//            if let data = response.result.value{
//              
//              let json = data as! NSDictionary
//              
//              let total:Int = json["total"] as! Int
//              if total > 0
//              {
//                let first = json["first"] as! [String:AnyObject]
//                let items = first["items"] as! [AnyObject]
//                for item in items
//                {
//                  let target = item["target"] as! [String:AnyObject]
//                  let source = target["source"] as! String
//                  if source == book.identifier
//                  {
//                    
//                    let selector = target["selector"] as! [String:AnyObject]
//                    let value = selector["value"] as! String
//                    
//                    completionHandler(value as String!, response.result.error as NSError?)
//                    print(value)
//                  }
//                }
//              }
//              else
//              {
//                completionHandler(nil, response.result.error as NSError?)
//              }
//              
//            }
//            break
//            
//          case .failure(_):
//            completionHandler(nil, response.result.error as NSError?)
//            break
//            
//          }
//        }
//      }
//    }
  }
  
  private class var headers:[String:String]
  {
    let authenticationString = "\(NYPLAccount.shared().barcode!):\(NYPLAccount.shared().pin!)"
    let authenticationData:Data = authenticationString.data(using: String.Encoding.ascii)!
    let authenticationValue = "Basic \(authenticationData.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters)))"
    
    let headers = ["Authorization": "\(authenticationValue)"]
    return headers
  }
}
