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
        ]
        ] as [String : Any]
      
      let url = NYPLConfiguration.mainFeedURL().appendingPathComponent("annotations/")
      
      postJSONRequest(book, url, parameters, NYPLAnnotations.headers)
    }
  }
  
  class func sync(_ book:NYPLBook, completionHandler: @escaping (_ responseObject: String?, _ error: NSError?) -> ()) {
    syncLastRead(book, completionHandler: completionHandler)
  }
  
  private class func postJSONRequest(_ book: NYPLBook, _ url: URL, _ parameters: [String:Any], _ headers: [String:String]?)
  {
    let jsonData: Data?
    do {
      jsonData = try JSONSerialization.data(withJSONObject: parameters, options: [.prettyPrinted])
    } catch {
      print("Network request abandoned: Could not create JSON from given parameters")
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
  //        print("Post Last-Read: Success")
        }
      } else {
        guard let error = error as? NSError else { return }
        if OfflineQueueStatusCodes.contains(error.code) {
          self.addToOfflineQueue(book, url, parameters)
          print("Network Response Error: \(error.localizedDescription)")
        }
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
  
  private class func syncLastRead(_ book:NYPLBook, completionHandler: @escaping (_ responseObject: String?,
    _ error: NSError?) -> ()) {
       
    if (NYPLAccount.shared().hasBarcodeAndPIN())
    {
      if book.annotationsURL != nil {
        
        var request = URLRequest(url: book.annotationsURL)
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
              print("JSON could not be created from data.")
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
                    let value = selector["value"] as! String
                    
                    completionHandler(value as String!, error as? NSError)
                    print(value)
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
  
  private class var headers: [String:String]
  {
    let authenticationString = "\(NYPLAccount.shared().barcode!):\(NYPLAccount.shared().pin!)"
    let authenticationData:Data = authenticationString.data(using: String.Encoding.ascii)!
    let authenticationValue = "Basic \(authenticationData.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters))"
    
    return ["Authorization" : "\(authenticationValue)",
            "Content-Type" : "application/json"]
  }
}
