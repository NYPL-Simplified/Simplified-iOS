//
//  NNYPLAnnotations.swift
//  Simplified
//
//  Created by Aferdita Muriqi on 10/18/16.
//  Copyright © 2016 NYPL Labs. All rights reserved.
//

import UIKit

final class NYPLAnnotations: NSObject {
  
  class func syncSettings(completionHandler: @escaping (_ syncSettingExist: Bool) -> ())
  {
    if (NYPLAccount.shared().hasBarcodeAndPIN() && AccountsManager.shared.currentAccount.supportsSimplyESync)
    {
      let annotationSettingsUrl = NYPLConfiguration.mainFeedURL()?.appendingPathComponent("patrons/me/")

      guard let url = annotationSettingsUrl else {
        return
      }
      var request = URLRequest.init(url: url,
                                    cachePolicy: .reloadIgnoringLocalCacheData,
                                    timeoutInterval: 30)
      request.httpMethod = "GET"
      
      for (headerKey, headerValue) in NYPLAnnotations.headers {
        request.setValue(headerValue, forHTTPHeaderField: headerKey)
      }
      
      let dataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
        
        guard let json = try? JSONSerialization.jsonObject(with: data!, options: []) as! [String:Any] else {
          Log.error(#file, "JSON could not be created from data.")
          return
        }
        
        guard let settings = json["settings"] as? [String:Any] else {
          Log.error(#file, "settings could not be found.")
          return
        }
        
        guard let syncSetting = settings["simplified:synchronize_annotations"] else {
          Log.error(#file, "simplified:synchronize_annotations could not be found.")
          return
        }
        
        if syncSetting is NSNull {
          completionHandler(false)
        }
        else
        {
//          NYPLSettings.shared().settingsSynchronizeAnnotations = syncSetting as! Bool
          completionHandler(true)
        }
        
      }
      dataTask.resume()
    }

  }
  
  class func updateSyncSettings(_ synchronize_annotations:Bool)
  {
  
    if (NYPLAccount.shared().hasBarcodeAndPIN() && AccountsManager.shared.currentAccount.supportsSimplyESync)
    {
      let annotationSettingsUrl = NYPLConfiguration.mainFeedURL()?.appendingPathComponent("patrons/me/")

      let parameters = [
        "settings":[
          "simplified:synchronize_annotations":  synchronize_annotations
        ]
        ] as [String : Any]
      
      if let url = annotationSettingsUrl {
        putJSONRequest(url, parameters, NYPLAnnotations.headers)
      } else {
        Log.error(#file, "MainFeedURL does not exist")
      }
      
    }
  
  }
  
  class func postLastRead(_ book:NYPLBook, cfi:NSString)
  {
    if (NYPLAccount.shared().hasBarcodeAndPIN() && AccountsManager.shared.currentAccount.supportsSimplyESync)
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
      
      let annotationsUrl = NYPLConfiguration.mainFeedURL()?.appendingPathComponent("annotations/")
      
      if let url = annotationsUrl {
        postJSONRequest(book, url, parameters, NYPLAnnotations.headers)
      } else {
        Log.error(#file, "MainFeedURL does not exist")
      }
    }
  }
  
  class func sync(_ book:NYPLBook, completionHandler: @escaping (_ responseObject: [String:String]?) -> ()) {
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
  
  private class func putJSONRequest(_ url: URL, _ parameters: [String:Any], _ headers: [String:String]?)
  {
    guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: [.prettyPrinted]) else {
      Log.error(#file, "Network request abandoned. Could not create JSON from given parameters.")
      return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "PUT"
    request.httpBody = jsonData
    
    if let headers = headers {
      for (headerKey, headerValue) in headers {
        request.setValue(headerValue, forHTTPHeaderField: headerKey)
      }
    }
    
    request.setValue("vnd.librarysimplified/user-profile+json", forHTTPHeaderField: "Content-Type")
    
    
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
      
      if let response = response as? HTTPURLResponse {
        if response.statusCode == 200 {

//          {
//            "simplified:authorization_expires": "2020-03-16T00:00:00Z",
//            "settings": {
//              "simplified:synchronize_annotations": true
//            }
//          }
          
          
        }
        else
        {
          Log.error(#file, "Response Status Code: \(response.statusCode). Description: \(HTTPURLResponse.localizedString(forStatusCode: response.statusCode))")
        }
      } else {
        guard let error = error as? NSError else { return }
        if NetworkQueue.StatusCodes.contains(error.code) {
          self.addToOfflineQueue(nil, url, parameters)
        }
        Log.error(#file, "Request Error Code: \(error.code). Description: \(error.localizedDescription)")
      }
    }
    task.resume()
  }
  
  private class func addToOfflineQueue(_ book: NYPLBook?, _ url: URL, _ parameters: [String:Any])
  {
    let libraryID = AccountsManager.shared.currentAccount.id
    let parameterData = try? JSONSerialization.data(withJSONObject: parameters, options: [.prettyPrinted])
    NetworkQueue.addRequest(libraryID, book?.identifier, url, .POST, parameterData, headers)
  }
  
  private class func syncLastRead(_ book:NYPLBook, completionHandler: @escaping (_ responseObject: [String:String]?) -> ()) {
       
    if (NYPLAccount.shared().hasBarcodeAndPIN() && book.annotationsURL != nil  && AccountsManager.shared.currentAccount.supportsSimplyESync)
    {
      var request = URLRequest.init(url: book.annotationsURL,
                                    cachePolicy: .reloadIgnoringLocalCacheData,
                                    timeoutInterval: 30)
      request.httpMethod = "GET"
      
      for (headerKey, headerValue) in NYPLAnnotations.headers {
        request.setValue(headerValue, forHTTPHeaderField: headerKey)
      }
      
      let dataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
        
        if error != nil {
          completionHandler(nil)
          return
        } else {
          
          guard let json = try? JSONSerialization.jsonObject(with: data!, options: []) as! [String:Any] else {
            Log.error(#file, "JSON could not be created from data.")
            completionHandler(nil)
            return
          }
          
          guard let total:Int = json["total"] as? Int else {
            completionHandler(nil)
            return
          }
          
          if total > 0
          {
            
            guard let first = json["first"] as? [String:AnyObject], let items = first["items"] as? [AnyObject] else {
              completionHandler(nil)
              return
            }
            
            for item in items
            {
              
              guard let target = item["target"] as? [String:AnyObject],
                let source = target["source"] as? String,
                let motivation = item["motivation"] as? String else {
                completionHandler(nil)
                return
              }
              
              if source == book.identifier && motivation == "http://librarysimplified.org/terms/annotation/idling"
              {
                
                guard let selector = target["selector"] as? [String:AnyObject], let serverCFI = selector["value"] as? String else {
                  completionHandler(nil)
                  return
                }
                
                var responseObject = ["serverCFI" : serverCFI]
                
                if let body = item["body"] as? [String:AnyObject],
                  let device = body["http://librarysimplified.org/terms/device"] as? String,
                  let time = body["http://librarysimplified.org/terms/time"] as? String
                {
                  responseObject["device"] = device
                  responseObject["time"] = time
                }
                
                Log.info(#file, "\(responseObject["serverCFI"])")
                completionHandler(responseObject)
                return
              }
            }
          } else {
            completionHandler(nil)
            return
          }
          
        }
      }
      dataTask.resume()
    }
    else
    {
      completionHandler(nil)
      return
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
