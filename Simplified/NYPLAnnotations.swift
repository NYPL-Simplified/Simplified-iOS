////
////  NNYPLAnnotations.swift
////  Simplified
////
////  Created by Aferdita Muriqi on 10/18/16.
////  Copyright © 2016 NYPL Labs. All rights reserved.
////
//
//import UIKit
//import Alamofire
//
//class NYPLAnnotations: NSObject {
//  
//  
//  class func postLastRead(_ book:NYPLBook, cfi:NSString)
//  {
//    
//    func convertStringToDictionary(_ text: String) -> [String:AnyObject]? {
//      if let data = text.data(using: String.Encoding.utf8) {
//        do {
//          return try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:AnyObject]
//        } catch let error as NSError {
//          print(error)
//        }
//      }
//      return nil
//    }
//    
//    if (NYPLAccount.shared().hasBarcodeAndPIN())
//    {
//      
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
//      ] as [String : Any]
//
//      Alamofire.request(.POST, NYPLConfiguration.circulationURL().URLByAppendingPathComponent("annotations/"), parameters:parameters, encoding: .JSON, headers:NYPLAnnotations.headers).response(completionHandler: { (request, response, data, error) in
//        
//          if response?.statusCode == 200
//          {
//            print("post last read successful")
//          }
//      })
//
//    }
//  }
//  
//  class func syncLastRead(_ book:NYPLBook, completionHandler: @escaping (_ responseObject: String?,
//    _ error: NSError?) -> ()) {
//    
//    func convertDataToDictionary(_ data: Data) -> [String:AnyObject]? {
//      do {
//        return try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject]
//      } catch let error as NSError {
//        print(error)
//      }
//      return nil
//    }
//        
//    if (NYPLAccount.shared().hasBarcodeAndPIN())
//    {
//      if book.annotationsURL != nil {
//        
//        Alamofire.request(.GET, book.annotationsURL.absoluteString, headers: NYPLAnnotations.headers).response { (request, response, data, error) in
//          
//          if error == nil
//          {
//            let json = convertDataToDictionary(data!)
//            
//            let total:Int = json!["total"] as! Int
//            if total > 0
//            {
//              let first = json!["first"] as! [String:AnyObject]
//              let items = first["items"] as! [AnyObject]
//              for item in items
//              {
//                let target = item["target"] as! [String:AnyObject]
//                let source = target["source"] as! String
//                if source == book.identifier
//                {
//                  
//                  let selector = target["selector"] as! [String:AnyObject]
//                  let value = selector["value"] as! String
//                  
//                  completionHandler(responseObject: value as String!, error: error)
//                  print(value)
//                }
//              }
//            }
//            else
//            {
//              completionHandler(responseObject: nil, error: error)
//            }
//          }
//          else
//          {
//            completionHandler(responseObject: nil, error: error)
//          }
//        }
//      }
//    }
//  }
//  
//  class func sync(_ book:NYPLBook, completionHandler: @escaping (_ responseObject: String?, _ error: NSError?) -> ()) {
//    syncLastRead(book, completionHandler: completionHandler)
//  }
//  
//  
//  class var headers:[String:String]
//  {
//    let authenticationString = "\(NYPLAccount.shared().barcode):\(NYPLAccount.shared().pin)"
//    let authenticationData:Data = authenticationString.data(using: String.Encoding.ascii)!
//    let authenticationValue = "Basic \(authenticationData.base64EncodedString(options: NSData.Base64EncodingOptions.lineLength64Characters)))"
//    
//    let headers = [
//      "Authorization": "\(authenticationValue)"      ]
//    
//    return headers
//  }
//  
//}
