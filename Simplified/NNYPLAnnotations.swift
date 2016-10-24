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
  
  
  class func postLastRead(book:NYPLBook, cfi:NSString)
  {
    
    func convertStringToDictionary(text: String) -> [String:AnyObject]? {
      if let data = text.dataUsingEncoding(NSUTF8StringEncoding) {
        do {
          return try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as? [String:AnyObject]
        } catch let error as NSError {
          print(error)
        }
      }
      return nil
    }
    
    if (NYPLAccount.sharedAccount().hasBarcodeAndPIN())
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
      ]
//      print(cfi)
//      print(parameters)

      Alamofire.request(.POST, "https://circulation.librarysimplified.org/annotations/", parameters:parameters, encoding: .JSON, headers:NYPLAnnotations.headers).response(completionHandler: { (request, response, data, error) in
        
          if response?.statusCode == 200
          {
            print("post last read successful")
          }
      })

    }
  }
  
  class func syncLastRead(book:NYPLBook, completionHandler: (responseObject: String?,
    error: NSError?) -> ()) {
    
    func convertDataToDictionary(data: NSData) -> [String:AnyObject]? {
      do {
        return try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String:AnyObject]
      } catch let error as NSError {
        print(error)
      }
      return nil
    }
        
    if (NYPLAccount.sharedAccount().hasBarcodeAndPIN())
    {
      if book.annotationsURL != nil {
        
        Alamofire.request(.GET, book.annotationsURL.absoluteString, headers: NYPLAnnotations.headers).response { (request, response, data, error) in
          
          if error == nil
          {
            let json = convertDataToDictionary(data!)
            
            let total:Int = json!["total"] as! Int
            if total > 0
            {
              let first = json!["first"] as! [String:AnyObject]
              let items = first["items"] as! [AnyObject]
              for item in items
              {
                let target = item["target"] as! [String:AnyObject]
                let source = target["source"] as! String
                if source == book.identifier
                {
                  
                  let selector = target["selector"] as! [String:AnyObject]
                  let value = selector["value"] as! String
                  
                  completionHandler(responseObject: value as String!, error: error)
                  print(value)
                }
              }
            }
            else
            {
              completionHandler(responseObject: nil, error: error)
            }
          }
          else
          {
            completionHandler(responseObject: nil, error: error)
          }
        }
      }
    }
  }
  
  class func sync(book:NYPLBook, completionHandler: (responseObject: String?, error: NSError?) -> ()) {
    //it passes your closure to makeAuthenticateUserCall
    syncLastRead(book, completionHandler: completionHandler)
  }
  
  
  class var headers:[String:String]
  {
    let authenticationString = "\(NYPLAccount.sharedAccount().barcode):\(NYPLAccount.sharedAccount().PIN)"
    let authenticationData:NSData = authenticationString.dataUsingEncoding(NSASCIIStringEncoding)!
    let authenticationValue = "Basic \(authenticationData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)))"
    
    let headers = [
      "Authorization": "\(authenticationValue)"      ]
    
    return headers
  }
  
}
