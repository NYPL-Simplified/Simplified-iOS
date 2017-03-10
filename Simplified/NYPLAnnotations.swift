//
//  NNYPLAnnotations.swift
//  Simplified
//
//  Created by Aferdita Muriqi on 10/18/16.
//  Copyright © 2016 NYPL Labs. All rights reserved.
//

import UIKit

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
  
  private class func postJSONRequest(_ url: URL, _ parameters: [String:Any], _ headers: [String:String]?)
  {

    //FIXME: this network code needs to be tested before being re-implemented. Alamofire was removed. Remove this comment after turning annotations/sync back on.
    
//    let jsonData: Data?
//    do {
//      jsonData = try JSONSerialization.data(withJSONObject: parameters)
//    } catch {
//      print("Network request abandoned: Could not create JSON from given parameters")
//      return
//    }
//    
//    var request = URLRequest(url: url)
//    request.httpMethod = "POST"
//    request.httpBody = jsonData
//    
//    if let headers = headers {
//      for (headerKey, headerValue) in headers {
//        request.setValue(headerValue, forHTTPHeaderField: headerKey)
//      }
//    }
//    
//    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
//      guard let response = response as? HTTPURLResponse else { return }
//      if response.statusCode == 200 {
//        print("Post Last-Read: Success")
//      } else {
//        guard let error = error as? NSError else { return }
//        if offlineQueueStatusCodes.contains(error.code) {
//          self.addToOfflineAnnotationsQueue(url, parameters)
//          print("Last Read Position Added to OfflineQueue. Response Error: \(error.localizedDescription)")
//        }
//      }
//    }
//    
//    task.resume()
  }
  
  private class func addToOfflineAnnotationsQueue(_ url: URL, _ parameters: [String:Any])
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
////          print("Replacing older offline queue entry")
//        }
//      }
//    }
//    let newRow = [url.absoluteString, parameters] as [Any]
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
//        postJSONRequest(url, queuedEvent[1] as! [String : Any], NYPLAnnotations.headers)
//      }
//    }
  }
  
  private class func syncLastRead(_ book:NYPLBook, completionHandler: @escaping (_ responseObject: String?,
    _ error: NSError?) -> ()) {
    
        //FIXME: this network code needs to be tested before being re-implemented. Alamofire was removed. Remove this comment after turning annotations/sync back on.
    
//    if (NYPLAccount.shared().hasBarcodeAndPIN())
//    {
//      if book.annotationsURL != nil {
//        
//        var request = URLRequest(url: book.annotationsURL)
//        request.httpMethod = "GET"
//        
//        for (headerKey, headerValue) in NYPLAnnotations.headers {
//          request.setValue(headerValue, forHTTPHeaderField: headerKey)
//        }
//        
//        let dataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
//          
//          if error != nil {
//            completionHandler(nil, error as? NSError)
//          } else {
//            
//            let jsonData: [String:Any]?
//            do {
//              jsonData = try JSONSerialization.jsonObject(with: data!, options: []) as? [String:Any]
//            } catch {
//              print("JSON could not be created from data.")
//              completionHandler(nil, nil)
//              return
//            }
//            
//            if let json = jsonData {
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
//                    let selector = target["selector"] as! [String:AnyObject]
//                    let value = selector["value"] as! String
//                    
//                    completionHandler(value as String!, error as? NSError)
//                    print(value)
//                  }
//                }
//              }
//            } else {
//              print("Unexpected data returned as JSON")
//              completionHandler(nil, nil)
//            }
//          }
//        }
//        dataTask.resume()
//      }
//    }
  }
  
  private class var headers: [String:String]
  {
    let authenticationString = "\(NYPLAccount.shared().barcode!):\(NYPLAccount.shared().pin!)"
    let authenticationData:Data = authenticationString.data(using: String.Encoding.ascii)!
    let authenticationValue = "Basic \(authenticationData.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters))"
    
    return ["Authorization" : "\(authenticationValue)",
      "Content-Type" : "application/json" ]
  }
}
