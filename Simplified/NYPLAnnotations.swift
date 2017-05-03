//
//  NNYPLAnnotations.swift
//  Simplified
//
//  Created by Aferdita Muriqi on 10/18/16.
//  Copyright © 2016 NYPL Labs. All rights reserved.
//

import UIKit

final class NYPLAnnotations: NSObject {
  
  class func getSyncSettings(completionHandler: @escaping (_ initialized: Bool, _ value:Bool) -> ())
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
        if (error == nil) {
          if let response = response as? HTTPURLResponse {
            if response.statusCode == 200 {
              
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
                completionHandler(false, false)
              }
              else
              {
                completionHandler(true, syncSetting as! Bool)
              }
            }
          }
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
        putSyncSettingsJSONRequest(url, parameters, NYPLAnnotations.headers)
      } else {
        Log.error(#file, "MainFeedURL does not exist")
      }
      
    }
    
  }
  
  private class func putSyncSettingsJSONRequest(_ url: URL, _ parameters: [String:Any], _ headers: [String:String]?)
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
        guard let error = error as NSError? else { return }
        if NetworkQueue.StatusCodes.contains(error.code) {
          self.addToOfflineQueue(nil, url, parameters)
        }
        Log.error(#file, "Request Error Code: \(error.code). Description: \(error.localizedDescription)")
      }
    }
    task.resume()
  }
  
  class func syncLastRead(_ book:NYPLBook, completionHandler: @escaping (_ responseObject: [String:String]?) -> ()) {
    
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
        postAnnotationJSONRequest(book, url, parameters, NYPLAnnotations.headers, completionHandler: { (success) in
          
          Log.debug(#file, "successfully posted last reading position")
          
        })
      } else {
        Log.error(#file, "MainFeedURL does not exist")
      }
    }
  }
  
  private class func postAnnotationJSONRequest(_ book: NYPLBook, _ url: URL, _ parameters: [String:Any], _ headers: [String:String]?, completionHandler: @escaping (_ success: Bool) -> ())
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
          completionHandler(true)
          debugPrint(#file, "Posted Last-Read \(((parameters["target"] as! [String:Any])["selector"] as! [String:Any])["value"] as! String)")
        }
      } else {
        
        guard let error = error as NSError? else { return }
        if NetworkQueue.StatusCodes.contains(error.code) {
          self.addToOfflineQueue(book, url, parameters)
        }
        completionHandler(false)
        Log.error(#file, "Request Error Code: \(error.code). Description: \(error.localizedDescription)")
      }
    }
    task.resume()
  }
  
  class func getBookmark(_ book:NYPLBook, _ cfi:NSString,  completionHandler: @escaping (_ responseObject: NYPLReaderBookmarkElement?) -> ()) {
    
    let responseJSON = try! JSONSerialization.jsonObject(with: cfi.data(using: String.Encoding.utf8.rawValue)!, options: JSONSerialization.ReadingOptions.mutableContainers) as! [String:String]
    
    let contentCFI = responseJSON["contentCFI"]!
    let idref = responseJSON["idref"]!
    
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
              let id = item["id"] as? String,
              let motivation = item["motivation"] as? String else {
                completionHandler(nil)
                return
            }
            
            if source == book.identifier && motivation.contains("bookmarking")
            {
              
              
              guard let selector = target["selector"] as? [String:AnyObject],
                let serverCFI = selector["value"] as? String else {
                  completionHandler(nil)
                  return
              }
              
              var responseObject:[String:Any] = ["serverCFI" : serverCFI]
              
              if let body = item["body"] as? [String:AnyObject],
                let device = body["http://librarysimplified.org/terms/device"] as? String,
                let time = body["http://librarysimplified.org/terms/time"] as? String,
                let chapter = body["http://librarysimplified.org/terms/chapter"] as? String,
                let progressWithinChapter = body["http://librarysimplified.org/terms/progressWithinChapter"] as? Float,
                let progressWithinBook = body["http://librarysimplified.org/terms/progressWithinBook"] as? Float
              {
                responseObject["device"] = device
                responseObject["time"] = time
                responseObject["chapter"] = chapter
                responseObject["progressWithinChapter"] = progressWithinChapter
                responseObject["progressWithinBook"] = progressWithinBook
              }
              
              
              let responseJSON = try! JSONSerialization.jsonObject(with: serverCFI.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions.mutableContainers) as! [String:String]
              
              if (contentCFI == responseJSON["contentCFI"]! && idref == responseJSON["idref"]!) {
                
                let bookmark = NYPLReaderBookmarkElement(annotationId: id, contentCFI: responseJSON["contentCFI"]!, idref: responseJSON["idref"]!, chapter: responseObject["chapter"] as? String, page: nil, location: serverCFI, progressWithinChapter: responseObject["progressWithinChapter"] as! Float, progressWithinBook: responseObject["progressWithinBook"] as! Float)
                bookmark.time = responseObject["time"] as? String
                bookmark.device = responseObject["device"] as? String
        

                completionHandler(bookmark)
                return
                
              }
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
  
  class func getBookmarks(_ book:NYPLBook, completionHandler: @escaping (_ bookmarks: [NYPLReaderBookmarkElement]) -> ()) {
    
    var bookmarks = [NYPLReaderBookmarkElement]()
    
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
          completionHandler(bookmarks)
          return
        } else {
          
          guard let json = try? JSONSerialization.jsonObject(with: data!, options: []) as! [String:Any] else {
            Log.error(#file, "JSON could not be created from data.")
            completionHandler(bookmarks)
            return
          }
          
          guard let total:Int = json["total"] as? Int else {
            completionHandler(bookmarks)
            return
          }
          
          if total > 0
          {
            
            guard let first = json["first"] as? [String:AnyObject], let items = first["items"] as? [AnyObject] else {
              completionHandler(bookmarks)
              return
            }
            
            
            for item in items
            {
              
              guard let target = item["target"] as? [String:AnyObject],
                let source = target["source"] as? String,
                let id = item["id"] as? String,
                let motivation = item["motivation"] as? String else {
                  completionHandler(bookmarks)
                  return
              }
              
              if source == book.identifier && motivation.contains("bookmarking")
              {
                
                
                guard let selector = target["selector"] as? [String:AnyObject],
                  let serverCFI = selector["value"] as? String else {
                    completionHandler(bookmarks)
                    return
                }
                
                var responseObject:[String:Any] = ["serverCFI" : serverCFI]
                
                if let body = item["body"] as? [String:AnyObject],
                  let device = body["http://librarysimplified.org/terms/device"] as? String,
                  let time = body["http://librarysimplified.org/terms/time"] as? String,
                  let chapter = body["http://librarysimplified.org/terms/chapter"] as? String,
                  let progressWithinChapter = body["http://librarysimplified.org/terms/progressWithinChapter"] as? Float,
                  let progressWithinBook = body["http://librarysimplified.org/terms/progressWithinBook"] as? Float
                {
                  responseObject["device"] = device
                  responseObject["time"] = time
                  responseObject["chapter"] = chapter
                  responseObject["progressWithinChapter"] = progressWithinChapter
                  responseObject["progressWithinBook"] = progressWithinBook
                }
                
                
                let responseJSON = try! JSONSerialization.jsonObject(with: serverCFI.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions.mutableContainers) as! [String:String]
                
                
                let bookmark = NYPLReaderBookmarkElement(annotationId: id, contentCFI: responseJSON["contentCFI"]!, idref: responseJSON["idref"]!, chapter: responseObject["chapter"] as? String, page: nil, location: serverCFI, progressWithinChapter: responseObject["progressWithinChapter"] as! Float, progressWithinBook: responseObject["progressWithinBook"] as! Float)
                bookmark.time = responseObject["time"] as? String
                bookmark.device = responseObject["device"] as? String

                bookmarks.append(bookmark)
                
              }
            }
            
            completionHandler(bookmarks)
            return
            
          } else {
            completionHandler(bookmarks)
            return
          }
          
        }
      }
      dataTask.resume()
    }
    else
    {
      completionHandler(bookmarks)
      return
    }
    
  }
  
  class func postBookmark(_ book:NYPLBook, cfi:NSString, bookmark:NYPLReaderBookmarkElement, completionHandler: @escaping (_ responseObject: NYPLReaderBookmarkElement?) -> ())
  {
    if (NYPLAccount.shared().hasBarcodeAndPIN() && AccountsManager.shared.currentAccount.supportsSimplyESync)
    {
      let parameters = [
        "@context": "http://www.w3.org/ns/anno.jsonld",
        "type": "Annotation",
        "motivation": "http://www.w3.org/ns/oa#bookmarking",
        "target":[
          "source":  book.identifier,
          "selector": [
            "type": "oa:FragmentSelector",
            "value": cfi
          ]
        ],
        "body": [
          "http://librarysimplified.org/terms/time" : NSDate().rfc3339String(),
          "http://librarysimplified.org/terms/device" : NYPLAccount.shared().deviceID,
          "http://librarysimplified.org/terms/chapter" : bookmark.chapter!,
          "http://librarysimplified.org/terms/progressWithinChapter" : bookmark.progressWithinChapter,
          "http://librarysimplified.org/terms/progressWithinBook" : bookmark.progressWithinBook,
        ]
        ] as [String : Any]
      
      let url = NYPLConfiguration.mainFeedURL()?.appendingPathComponent("annotations/")
      
      if let url = url {
        
        postAnnotationJSONRequest(book, url, parameters, NYPLAnnotations.headers, completionHandler: { (success) in
          
          if (success) {
            getBookmark(book, cfi, completionHandler: {(bookmark) in
              
              completionHandler(bookmark!)
              
            })
          }
          else {
            completionHandler(nil)
          }
        })
        
      } else {
        Log.error(#file, "MainFeedURL does not exist")
      }
    }
  }
  
  class func deleteBookmark(annotationId:NSString)
  {
    let url: URL = URL(string: annotationId as String)!
    var request = URLRequest(url: url)
    request.httpMethod = "DELETE"
    
    if let headers = NYPLAnnotations.headers as [String:String]? {
      for (headerKey, headerValue) in headers {
        request.setValue(headerValue, forHTTPHeaderField: headerKey)
      }
    }
    
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
      
      if let response = response as? HTTPURLResponse {
        print("NYPLAnnotations::deleteBookmark, response.statusCode is \(response.statusCode)")
        
        if response.statusCode == 200 {
          debugPrint(#file, "Deleted Bookmark")
        }
      } else {
        guard let error = error as NSError? else { return }
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
  
  class var headers: [String:String]
  {
    let authenticationString = "\(NYPLAccount.shared().barcode!):\(NYPLAccount.shared().pin!)"
    let authenticationData:Data = authenticationString.data(using: String.Encoding.ascii)!
    let authenticationValue = "Basic \(authenticationData.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters))"
    
    return ["Authorization" : "\(authenticationValue)",
      "Content-Type" : "application/json"]
  }
}
