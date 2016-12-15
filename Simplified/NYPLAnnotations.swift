//
//  NNYPLAnnotations.swift
//  Simplified
//
//  Created by Aferdita Muriqi on 10/18/16.
//  Copyright © 2016 NYPL Labs. All rights reserved.
//

import UIKit
import Alamofire

class NYPLAnnotations: NSObject {
  
  
  class func postLastRead(_ book:NYPLBook, cfi:NSString)
  {
    
    //Cannot make AF 4.0 request in iOS8
    if floor(NSFoundationVersionNumber) < NSFoundationVersionNumber_iOS_9_0 {
      return;
    }
    
    func convertStringToDictionary(_ text: String) -> [String:AnyObject]? {
      if let data = text.data(using: String.Encoding.utf8) {
        do {
          return try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:AnyObject]
        } catch let error as NSError {
          print(error)
        }
      }
      return nil
    }
    
    if (NYPLAccount.shared().hasBarcodeAndPIN())
    {
      
      let parameters = [
        "@context": "http://www.w3.org/ns/anno.jsonld",
        "type": "Annotation",
        "motivation": "http://librarysimplified.org/terms/annotation/idling",
        "target":[
          "source": book.identifier,
          "selector": [
            "type": "oa:FragmentSelector",
            "value": cfi
          ]
        ]
      ] as [String : Any]
      
      let url: NSURL = NYPLConfiguration.mainFeedURL().appendingPathComponent("annotations/") as NSURL
  
      Alamofire.request(url.absoluteString!, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: NYPLAnnotations.headers).responseData { (response:DataResponse) in
        
          if response.response?.statusCode == 200
          {
            print("post last read successful")
          }
      }
    }
  }
  
  class func syncLastRead(_ book:NYPLBook, completionHandler: @escaping (_ responseObject: String?,
    _ error: NSError?) -> ()) {
    
    //Cannot make AF 4.0 request in iOS8
    if floor(NSFoundationVersionNumber) < NSFoundationVersionNumber_iOS_9_0 {
      return;
    }
    
    if (NYPLAccount.shared().hasBarcodeAndPIN())
    {
      if book.annotationsURL != nil {
        
        Alamofire.request(book.annotationsURL.absoluteString, method: .get, parameters: ["":""], encoding: URLEncoding.default, headers: NYPLAnnotations.headers).responseJSON { (response:DataResponse<Any>) in
          
          switch(response.result) {
          case .success(_):
            if let data = response.result.value{
              
              let json = data as! NSDictionary
              
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
                    
                    completionHandler(value as String!, response.result.error as NSError?)
                    print(value)
                  }
                }
              }
              else
              {
                completionHandler(nil, response.result.error as NSError?)
              }
              
            }
            break
            
          case .failure(_):
            completionHandler(nil, response.result.error as NSError?)
            break
            
          }
        }
      }
    }
  }
  
  class func sync(_ book:NYPLBook, completionHandler: @escaping (_ responseObject: String?, _ error: NSError?) -> ()) {
    syncLastRead(book, completionHandler: completionHandler)
  }
  
  
  class var headers:[String:String]
  {
    let authenticationString = "\(NYPLAccount.shared().barcode!):\(NYPLAccount.shared().pin!)"
    let authenticationData:Data = authenticationString.data(using: String.Encoding.ascii)!
    let authenticationValue = "Basic \(authenticationData.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters)))"
    
    let headers = [
      "Authorization": "\(authenticationValue)"      ]
    
    return headers
  }
  
}
