import UIKit

///  Handling requests and certain actions related to:
///  OPDS Annotations saving & syncing

final class NYPLAnnotations: NSObject {

  // MARK: - Sync Settings

  // Query Server: If it's the user's first time, present an Alert Controller.
  // Attempt to update server if user selects YES to enable.
  // Notify the caller whether or not the device can use sync and update any logic/UI.
  // A client will not turn OFF sync server-side until a better UX is determined.
  
  // One byproduct of this, every time a user signs in fresh, it will default that
  // client sync setting back to on until they disable it completely from the server.
  
  // userHasSeenFirstTimeSyncMessage is how we know if a user explicitly chose "no"
  
  //GODO still need to check the logic of this method...

  class func requestServerSyncSettingWithUserAlert(
    _ completion: @escaping (_ enableSync: Bool) -> ()) {
    
    if !accountSatisfiesSyncConditions() ||
      NYPLSettings.shared().userHasSeenFirstTimeSyncMessage == true {
      Log.debug(#file, "Account does not satisfy conditions for sync request.")
      return
    }

    self.permissionUrlRequest { (initialized, syncIsPermitted) in

      if (initialized && syncIsPermitted) {
        completion(true)
        NYPLSettings.shared().userHasSeenFirstTimeSyncMessage = true;
        Log.debug(#file, "Sync has already been enabled on the server. Enable here as well.")
        return
      } else if (!initialized) {
        Log.debug(#file, "Sync has never been initialized for the patron. Showing UIAlertController flow.")
        let title = "SimplyE Sync"
        let message = "Enable sync to save your reading position and bookmarks to your other devices.\n\nYou can change this any time in Settings."
        let alertController = NYPLAlertController.init(title: title, message: message, preferredStyle: .alert)
        let notNowAction = UIAlertAction.init(title: "Not Now", style: .default, handler: { action in
          completion(false)
          NYPLSettings.shared().userHasSeenFirstTimeSyncMessage = true;
        })
        let enableSyncAction = UIAlertAction.init(title: "Enable Sync", style: .default, handler: { action in
          self.updateServerSyncSetting(toEnabled: true) { success in
            if success {
              completion(true)
            } else {
              self.handleSyncSettingError()
              completion(false)
            }
            NYPLSettings.shared().userHasSeenFirstTimeSyncMessage = true;
          }
        })
        alertController.addAction(notNowAction)
        alertController.addAction(enableSyncAction)
        if #available(iOS 9.0, *) {
          alertController.preferredAction = enableSyncAction
        }
        alertController.present(fromViewControllerOrNil: nil, animated: true, completion: nil)
      } else {
        completion(false)
      }
    }
  }
  
  class func updateServerSyncSetting(toEnabled enabled: Bool, completion:@escaping (Bool)->()) {
    if (NYPLAccount.shared().hasBarcodeAndPIN() &&
      AccountsManager.shared.currentAccount.supportsSimplyESync) {
      guard let patronAnnotationSettingUrl = NYPLConfiguration.mainFeedURL()?.appendingPathComponent("patrons/me/") else {
        Log.error(#file, "Could not create Annotations URL from Main Feed URL. Abandoning attempt to update sync setting.")
        completion(false)
        return
      }
      let parameters = ["settings": ["simplified:synchronize_annotations": enabled]] as [String : Any]
      syncSettingUrlRequest(patronAnnotationSettingUrl, parameters, 10, completion)
    }
  }

  // 'initialized' == true if the value of 'syncIsPermitted' has ever been set on the server
  private class func permissionUrlRequest(completionHandler: @escaping (_ initialized: Bool, _ syncIsPermitted: Bool) -> ()) {

    if (NYPLAccount.shared().hasBarcodeAndPIN() && AccountsManager.shared.currentAccount.supportsSimplyESync) {

      guard let annotationSettingsUrl = NYPLConfiguration.mainFeedURL()?.appendingPathComponent("patrons/me/") else {
        Log.error(#file, "Failed to create Annotations URL. Abandoning attempt to retrieve sync setting.")
        return
      }
      //GODO need to add error messages for users and logging
      var request = URLRequest.init(url: annotationSettingsUrl,
                                    cachePolicy: .reloadIgnoringLocalCacheData,
                                    timeoutInterval: 15)
      request.httpMethod = "GET"
      setDefaultAnnotationHeaders(forRequest: &request)

      let dataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in

        DispatchQueue.main.async {

          if let error = error as NSError? {
            Log.error(#file, "Request Error Code: \(error.code). Description: \(error.localizedDescription)")
            return
          }
          guard let data = data,
          let response = (response as? HTTPURLResponse) else {
            Log.error(#file, "No Data or No Server Response present after request.")
            return
          }

          if response.statusCode == 200 {
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String:Any],
            let settings = json["settings"] as? [String:Any],
            let syncSetting = settings["simplified:synchronize_annotations"] {
              if syncSetting is NSNull {
                completionHandler(false, false)
              } else {
                completionHandler(true, syncSetting as? Bool ?? false)
              }
            } else {
              Log.error(#file, "Error parsing JSON or finding sync-setting key/value.")
            }
          } else {
            Log.error(#file, "Server response returned error code: \(response.statusCode))")
          }
        }
      }
      dataTask.resume()
    } else {
      Log.debug(#file, "Skipping sync check. Account does not meet requirements to support sync.")
    }
  }
  
  private class func syncSettingUrlRequest(_ url: URL,
                                           _ parameters: [String:Any],
                                           _ timeout: Double?,
                                           _ completion: @escaping (Bool)->()) {
    guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: [.prettyPrinted]) else {
      Log.error(#file, "Network request abandoned. Could not create JSON from given parameters.")
      completion(false)
      return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "PUT"
    request.httpBody = jsonData
    setDefaultAnnotationHeaders(forRequest: &request)
    request.setValue("vnd.librarysimplified/user-profile+json", forHTTPHeaderField: "Content-Type")
    if let timeout = timeout {
      request.timeoutInterval = timeout
    }
    
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in

      DispatchQueue.main.async {

        if let error = error as NSError? {
          Log.error(#file, "Request Error Code: \(error.code). Description: \(error.localizedDescription)")
          if NetworkQueue.StatusCodes.contains(error.code) {
            self.addToOfflineQueue(nil, url, parameters)
          }
          completion(false)
          return
        }
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
          Log.error(#file, "No response received from server")
          completion(false)
          return
        }

        if statusCode == 200 {
          completion(true)
        } else {
          Log.error(#file, "Server Response Error. Status Code: \(statusCode)")
          completion(false)
        }
      }
    }
    task.resume()
  }

  class func handleSyncSettingError() {
    let title = NSLocalizedString("Error Changing Sync Setting", comment: "")
    let message = NSLocalizedString("There was a problem contacting the server.\nPlease make sure you are connected to the internet, or try again later.", comment: "")
    let alert = NYPLAlertController.init(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction.init(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
    alert.present(fromViewControllerOrNil: nil, animated: true, completion: nil)
  }

  // MARK: - Reading Position
  
  class func syncReadingPosition(ofBook bookID: String?, toURL url:URL?,
                                 completionHandler: @escaping (_ responseObject: [String:String]?) -> ()) {
    
    guard let url = url, let bookID = bookID else {
      Log.error(#file, "Required parameters are nil.")
      return
    }
    
    if (NYPLAccount.shared().hasBarcodeAndPIN() == false) ||
      (AccountsManager.shared.currentAccount.supportsSimplyESync == false) {
      Log.debug(#file, "Not signed in or acct does not support it.")
      return
    }

    var request = URLRequest.init(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
    request.httpMethod = "GET"
    setDefaultAnnotationHeaders(forRequest: &request)
    
    let dataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
      
      if let error = error as NSError? {
        Log.error(#file, "Request Error Code: \(error.code). Description: \(error.localizedDescription)")
        completionHandler(nil)
        return
      }
      guard let data = data,
        let json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String:Any] else {
          Log.error(#file, "JSON could not be created from data, or data was nil.")
          completionHandler(nil)
          return
      }
      if let total = json["total"] as? Int {
        if total <= 0 {
          Log.error(#file, "\"total\" key was empty")
          completionHandler(nil)
          return
        }
      }
      guard let first = json["first"] as? [String:AnyObject],
        let items = first["items"] as? [AnyObject] else {
          completionHandler(nil)
          return
      }
      
      for item in items {
        guard let target = item["target"] as? [String:AnyObject],
          let source = target["source"] as? String,
          let motivation = item["motivation"] as? String else {
            completionHandler(nil)
            return
        }
        
        if source == bookID && motivation == "http://librarysimplified.org/terms/annotation/idling" {
          
          guard let selector = target["selector"] as? [String:AnyObject],
            let serverCFI = selector["value"] as? String else {
              completionHandler(nil)
              return
          }
          
          var responseObject = ["serverCFI" : serverCFI]
          
          if let body = item["body"] as? [String:AnyObject],
            let device = body["http://librarysimplified.org/terms/device"] as? String,
            let time = body["http://librarysimplified.org/terms/time"] as? String {
            responseObject["device"] = device
            responseObject["time"] = time
          }
          
          completionHandler(responseObject)
          return
        }
      }
    }
    dataTask.resume()
  }
  
  class func postReadingPosition(forBook bookID: String, annotationsURL:URL?, cfi: NSString) {
    
    guard let annotationsURL = annotationsURL else {
      Log.error(#file, "Required parameter was nil.")
      return
    }
    if !accountSatisfiesSyncConditions() {
      Log.debug(#file, "Account does not support sync.")
      return
    }
    
    let parameters = [
      "@context": "http://www.w3.org/ns/anno.jsonld",
      "type": "Annotation",
      "motivation": "http://librarysimplified.org/terms/annotation/idling",
      "target": [
        "source": bookID,
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
    
    postAnnotation(forBook: bookID, toUrl: annotationsURL, withParameters: parameters) { success in
      Log.debug(#file, "Annotation posted successfully to the server.")
    }
  }
  
  private class func postAnnotation(forBook bookID: String,
                                    toUrl url: URL,
                                    withParameters parameters: [String:Any],
                                    _ completionHandler: @escaping (_ success: Bool) -> ()) {

    guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: [.prettyPrinted]) else {
      Log.error(#file, "Network request abandoned. Could not create JSON from given parameters.")
      return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = jsonData
    setDefaultAnnotationHeaders(forRequest: &request)
    
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in

      if let error = error as NSError? {
        Log.error(#file, "Request Error Code: \(error.code). Description: \(error.localizedDescription)")
        if NetworkQueue.StatusCodes.contains(error.code) {
          self.addToOfflineQueue(bookID, url, parameters)
        }
        completionHandler(false)
      }
      guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
        Log.error(#file, "No response received from server")
        completionHandler(false)
        return
      }

      if statusCode == 200 {
        Log.debug(#file, "Marked Reading Position To Server: \(((parameters["target"] as! [String:Any])["selector"] as! [String:Any])["value"] as! String)")
        completionHandler(true)
      } else {
        Log.error(#file, "Server Response Error. Status Code: \(statusCode)")
        completionHandler(false)
      }
    }
    task.resume()
  }

  // MARK: - Bookmarks

  //GODO need to test this method
  class func getBookmark(book id:String?,
                         atURL annotationUrl:URL?,
                         locationCFI cfi:NSString,
                         completionHandler: @escaping (_ responseObject: NYPLReaderBookmarkElement?) -> ()) {
    
    guard let data = cfi.data(using: String.Encoding.utf8.rawValue),
      let responseJSON = try? JSONSerialization.jsonObject(with: data,
      options: JSONSerialization.ReadingOptions.mutableContainers) as! [String:Any] else {
        Log.error(#file, "Error creating JSON Object")
        return
    }
    guard let localContentCfi = responseJSON["contentCFI"] as? String,
      let localIdref = responseJSON["idref"] as? String else {
        Log.error(#file, "Could not get contentCFI or idref from responseJSON")
        return
    }

    getBookmarks(forBook: id, atURL: annotationUrl) { bookmarks in
      completionHandler(bookmarks
        .filter({ $0.contentCFI == localContentCfi && $0.idref == localIdref })
        .first)
    }
  }
  
  class func getBookmarks(forBook bookID:String?, atURL annotationURL:URL?, completionHandler: @escaping (_ bookmarks: [NYPLReaderBookmarkElement]) -> ()) {
    
    guard let bookID = bookID, let annotationURL = annotationURL else {
      Log.error(#file, "Required parameter was nil.")
      return
    }
    
    if !NYPLAccount.shared().hasBarcodeAndPIN() ||
      !AccountsManager.shared.currentAccount.supportsSimplyESync {
      Log.debug(#file, "Account does not support sync.")
      return
    }
    
    var bookmarks = [NYPLReaderBookmarkElement]()

    var request = URLRequest.init(url: annotationURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
    request.httpMethod = "GET"
    setDefaultAnnotationHeaders(forRequest: &request)
    
    let dataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
      
      if let error = error as NSError? {
        Log.error(#file, "Request Error Code: \(error.code). Description: \(error.localizedDescription)")
        completionHandler(bookmarks)
        return
      }
      guard let data = data,
        let json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String:Any] else {
          Log.error(#file, "JSON could not be created from data.")
          completionHandler(bookmarks)
          return
      }
      if let total = json["total"] as? Int {
        if total <= 0 {
          Log.error(#file, "\"total\" key was empty")
          return
        }
      }
      guard let first = json["first"] as? [String:AnyObject],
        let items = first["items"] as? [AnyObject] else {
          completionHandler(bookmarks)
          return
      }

      for item in items {
        if let bookmark = createBookmarkElement(bookID, item) {
          bookmarks.append(bookmark)
        } else {
          Log.error(#file, "Could not create bookmark element from item.")
          continue
        }
      }
      completionHandler(bookmarks)
    }
    dataTask.resume()
  }

  private class func createBookmarkElement(_ bookID: String, _ item: AnyObject) -> NYPLReaderBookmarkElement? {

    guard let target = item["target"] as? [String:AnyObject],
    let source = target["source"] as? String,
    let id = item["id"] as? String,
    let motivation = item["motivation"] as? String else {
      Log.error(#file, "Error parsing key/values for target.")
      return nil
    }

    if source == bookID && motivation.contains("bookmarking") {

      guard let selector = target["selector"] as? [String:AnyObject],
        let serverCFI = selector["value"] as? String,
        let body = item["body"] as? [String:AnyObject] else {
          Log.error(#file, "ServerCFI could not be parsed.")
          return nil
      }

      guard let device = body["http://librarysimplified.org/terms/device"] as? String,
      let time = body["http://librarysimplified.org/terms/time"] as? String,
      let progressWithinChapter = body["http://librarysimplified.org/terms/progressWithinChapter"] as? Float,
      let progressWithinBook = body["http://librarysimplified.org/terms/progressWithinBook"] as? Float else {
        Log.error(#file, "Error reading required bookmark key/values from body")
        return nil
      }
      let chapter = body["http://librarysimplified.org/terms/chapter"] as? String

      guard let data = serverCFI.data(using: String.Encoding.utf8),
        let serverCfiJsonObject = try? JSONSerialization.jsonObject(with: data,
          options: JSONSerialization.ReadingOptions.mutableContainers) as! [String:String],
        let serverCfiJson = serverCfiJsonObject["contentCFI"],
        let serverIdrefJson = serverCfiJsonObject["idref"] else {
          Log.error(#file, "Error serializing serverCFI into JSON.")
          return nil
      }

      //GODO any of the previous '!' var's I'm assuming were not optional
      let bookmark = NYPLReaderBookmarkElement(annotationId: id,
                                               contentCFI: serverCfiJson,
                                               idref: serverIdrefJson,
                                               chapter: chapter ?? "",
                                               page: nil,
                                               location: serverCFI,
                                               progressWithinChapter: progressWithinChapter,
                                               progressWithinBook: progressWithinBook)
      bookmark.time = time
      bookmark.device = device
      return bookmark
    } else {
      Log.error(#file, "'source' key/value does not match current NYPLBook object ID, or 'motivation' key/value is invalid.")
    }
    return nil
  }
  
  class func postBookmark(forBook bookID: String,
                          toURL annotationsURL: URL?,
                          cfi: NSString,
                          bookmark: NYPLReaderBookmarkElement,
                          completionHandler: @escaping (_ responseObject: NYPLReaderBookmarkElement?) -> ())
  {
    
    //GODO these may be able to be consolidated
    guard let annotationsURL = annotationsURL else {
      Log.error(#file, "Required parameter was nil.")
      return
    }
    
    if !NYPLAccount.shared().hasBarcodeAndPIN() ||
      !AccountsManager.shared.currentAccount.supportsSimplyESync {
      Log.debug(#file, "Account does not support sync.")
      return
    }

    let parameters = [
      "@context": "http://www.w3.org/ns/anno.jsonld",
      "type": "Annotation",
      "motivation": "http://www.w3.org/ns/oa#bookmarking",
      "target": [
        "source": bookID,
        "selector": [
          "type": "oa:FragmentSelector",
          "value": cfi
        ]
      ],
      "body": [
        "http://librarysimplified.org/terms/time" : NSDate().rfc3339String(),
        "http://librarysimplified.org/terms/device" : NYPLAccount.shared().deviceID,
        "http://librarysimplified.org/terms/chapter" : bookmark.chapter as Any,
        "http://librarysimplified.org/terms/progressWithinChapter" : bookmark.progressWithinChapter,
        "http://librarysimplified.org/terms/progressWithinBook" : bookmark.progressWithinBook,
      ]
      ] as [String : Any]
    
    postAnnotation(forBook: bookID, toUrl: annotationsURL, withParameters: parameters) { success in
      if success {
        getBookmark(book: bookID, atURL: annotationsURL, locationCFI: cfi, completionHandler: { bookmark in
          completionHandler(bookmark)
        })
      } else {
        completionHandler(nil)
      }
    }
  }
  
  class func deleteBookmark(annotationId:NSString) {
    guard let url: URL = URL(string: annotationId as String) else {
      Log.error(#file, "Invalid URL Created")
      return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "DELETE"
    setDefaultAnnotationHeaders(forRequest: &request)
    
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
      if (response as? HTTPURLResponse)?.statusCode == 200 {
        Log.info(#file, "Deleted Bookmark")
      } else {
        guard let error = error as NSError? else { return }
        Log.error(#file, "Request Error Code: \(error.code). Description: \(error.localizedDescription)")
      }
    }
    task.resume()
  }

  // MARK: -
  
  class func accountSatisfiesSyncConditions() -> Bool {
    let acct = AccountsManager.shared.currentAccount
    return NYPLAccount.shared().hasBarcodeAndPIN() && acct.supportsSimplyESync
  }
  
  private class func addToOfflineQueue(_ bookID: String?, _ url: URL, _ parameters: [String:Any]) {
    let libraryID = AccountsManager.shared.currentAccount.id
    let parameterData = try? JSONSerialization.data(withJSONObject: parameters, options: [.prettyPrinted])
    NetworkQueue.addRequest(libraryID, bookID, url, .POST, parameterData, headers)
  }

  class func setDefaultAnnotationHeaders(forRequest request: inout URLRequest) {
    for (headerKey, headerValue) in NYPLAnnotations.headers {
      request.setValue(headerValue, forHTTPHeaderField: headerKey)
    }
  }
  
  class var headers: [String:String] {
    if let barcode = NYPLAccount.shared().barcode, let pin = NYPLAccount.shared().pin {
      let authenticationString = "\(barcode):\(pin)"
      if let authenticationData = authenticationString.data(using: String.Encoding.ascii) {
        let authenticationValue = "Basic \(authenticationData.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters))"
        return ["Authorization" : "\(authenticationValue)",
                "Content-Type" : "application/json"]
      } else {
        Log.error(#file, "Error formatting auth headers.")
      }
    } else {
      Log.error(#file, "Attempted to create authorization header without a barcode or pin.")
    }
    return ["Authorization" : "",
            "Content-Type" : "application/json"]
  }
  
}
