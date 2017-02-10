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
    if (NYPLAccount.shared().hasBarcodeAndPIN())
    {
      let parameters = [
        "@context": "http://www.w3.org/ns/anno.jsonld",
        "type": "Annotation",
        "motivation": "http://librarysimplified.org/terms/annotation/idling",
        "target":[
          "source":  book.identifier,
          "selector": [
            "type": "oa:FragmentSelector",
            "value": cfi
          ]
        ],
        "body": [
          "http://librarysimplified.org/terms/time" : NSDate().rfc3339String(),
          "http://librarysimplified.org/terms/device" : NYPLAccount.shared().deviceID
        ]
        ] as [String : Any]
      
      let url = NYPLConfiguration.mainFeedURL().appendingPathComponent("annotations/")
      
      postJSONRequest(book, url, parameters, NYPLAnnotations.headers)
    }
  }
  
  class func sync(_ book:NYPLBook, completionHandler: @escaping (_ responseObject: [String:String]?, _ error: NSError?) -> ()) {
    syncLastRead(book, completionHandler: completionHandler)
  }
  
  private class func postJSONRequest(_ book: NYPLBook, _ url: URL, _ parameters: [String:Any], _ headers: [String:String]?)
  {
    guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: [.prettyPrinted]) else {
      Log.error(#file, "Network request abandoned. Could not create JSON from given parameters.")
      return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = jsonData
    
    if let headers = headers {
      for (headerKey, headerValue) in headers {
        request.setValue(headerValue, forHTTPHeaderField: headerKey)
      }
    }
    
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
      
      if let response = response as? HTTPURLResponse {
        if response.statusCode == 200 {
          debugPrint(#file, "Posted Last-Read \(((parameters["target"] as! [String:Any])["selector"] as! [String:Any])["value"] as! String)")
        }
      } else {
        guard let error = error as? NSError else { return }
        if NetworkQueue.StatusCodes.contains(error.code) {
          self.addToOfflineQueue(book, url, parameters)
        }
        Log.error(#file, "Request Error Code: \(error.code). Description: \(error.localizedDescription)")
      }
    }
    task.resume()
  }
  
  private class func addToOfflineQueue(_ book: NYPLBook, _ url: URL, _ parameters: [String:Any])
  {
    let libraryID = AccountsManager.shared.currentAccount.id
    let parameterData = try? JSONSerialization.data(withJSONObject: parameters, options: [.prettyPrinted])
    NetworkQueue.addRequest(libraryID, book.identifier, url, .POST, parameterData, headers)
  }
  
  private class func syncLastRead(_ book:NYPLBook, completionHandler: @escaping (_ responseObject: [String:String]?,
    _ error: NSError?) -> ()) {
       
    if (NYPLAccount.shared().hasBarcodeAndPIN())
    {
      if book.annotationsURL != nil {
        
        var request = URLRequest.init(url: book.annotationsURL,
                                      cachePolicy: .reloadIgnoringLocalCacheData,
                                      timeoutInterval: 30)
        request.httpMethod = "GET"
        
        for (headerKey, headerValue) in NYPLAnnotations.headers {
          request.setValue(headerValue, forHTTPHeaderField: headerKey)
        }
        
        let dataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
          
          if error != nil {
            completionHandler(nil, error as? NSError)
          } else {
            
            let jsonData: [String:Any]?
            do {
              jsonData = try JSONSerialization.jsonObject(with: data!, options: []) as? [String:Any]
            } catch {
              Log.error(#file, "JSON could not be created from data.")
              completionHandler(nil, nil)
              return
            }
            
            if let json = jsonData {
              let total:Int = json["total"] as! Int
              if total > 0
              {
                let first = json["first"] as! [String:AnyObject]
                let items = first["items"] as! [AnyObject]
                for item in items
                {
                  let target = item["target"] as! [String:AnyObject]
                  let source = target["source"] as! String
                  if source == book.identifier
                  {
                    let selector = target["selector"] as! [String:AnyObject]
                    let serverCFI = selector["value"] as! String
                    
                    var responseObject = ["serverCFI" : serverCFI]
                    
                    if let body = item["body"] as? [String:AnyObject],
                      let device = body["http://librarysimplified.org/terms/device"] as? String,
                      let time = body["http://librarysimplified.org/terms/time"] as? String
                    {
                        responseObject["device"] = device
                        responseObject["time"] = time
                    }
                    
                    completionHandler(responseObject, error as? NSError)
                    Log.info(#file, "\(responseObject["serverCFI"])")
                  }
                }
              } else {
                completionHandler(nil, error as? NSError)
              }
            } else {
              completionHandler(nil, error as? NSError)
            }
          }
        }
        dataTask.resume()
      }
    }
  }
  
  class var headers: [String:String]
  {
    let authenticationString = "\(NYPLAccount.shared().barcode!):\(NYPLAccount.shared().pin!)"
    let authenticationData:Data = authenticationString.data(using: String.Encoding.ascii)!
    let authenticationValue = "Basic \(authenticationData.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters))"
    
    return ["Authorization" : "\(authenticationValue)",
            "Content-Type" : "application/json"]
  }
}
