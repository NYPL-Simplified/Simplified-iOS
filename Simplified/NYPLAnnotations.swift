import UIKit

@objcMembers final class NYPLAnnotations: NSObject {

  // key names returned by the server in annotations api responses
  static let serverCFIKey = "serverCFI"
  static let serverDeviceKey = "device"

  // MARK: - Sync Settings

  /// Shows (if needed) the opt-in flow for syncing the user bookmarks and
  /// reading position on the server.
  ///
  /// This is implemented with an alert that is displayed once for the current
  /// library once the user is signed in, i.e.:
  /// - If the user has never seen it before, show it.
  /// - If the user has seen it on one of their other devices, don't show it.
  /// Opting in will attempt to enable on the server, with appropriate error handling.
  /// - Note: This flow will be run only for the user account on the currently
  /// selected library. Anything else will result in a no-op.
  /// - Parameters:
  ///   - userAccount: the account to attempt to enable annotations-syncing on.
  ///   - completion: if a network request is actually performed, this block
  /// is guaranteed to be called on the Main queue. Otherwise, this is called
  /// either on the same thread the function was invoked on or on the main
  /// thread.
  class func requestServerSyncStatus(forAccount userAccount: NYPLUserAccount,
                                     completion: @escaping (_ enableSync: Bool) -> ()) {
    
    guard syncIsPossible(userAccount) else {
      Log.debug(#file, "Account does not satisfy conditions for sync setting request.")
      completion(false)
      return
    }

    let settings = NYPLSettings.shared

    if (settings.userHasSeenFirstTimeSyncMessage == true &&
        AccountsManager.shared.currentAccount?.details?.syncPermissionGranted == false) {
      completion(false)
      return
    }

    self.permissionUrlRequest { (initialized, syncIsPermitted) in

      if (initialized && syncIsPermitted) {
        completion(true)
        settings.userHasSeenFirstTimeSyncMessage = true;
        Log.debug(#file, "Sync has already been enabled on the server. Enable here as well.")
        return
      } else if (!initialized && settings.userHasSeenFirstTimeSyncMessage == false) {
        Log.debug(#file, "Sync has never been initialized for the patron. Showing UIAlertController flow.")
        #if OPENEBOOKS
        let title = "Open eBooks Sync"
        #else
        let title = "SimplyE Sync"
        #endif
        let message = "Enable sync to save your reading position and bookmarks to your other devices.\n\nYou can change this any time in Settings."
        let alertController = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        let notNowAction = UIAlertAction.init(title: "Not Now", style: .default, handler: { action in
          completion(false)
          settings.userHasSeenFirstTimeSyncMessage = true;
        })
        let enableSyncAction = UIAlertAction.init(title: "Enable Sync", style: .default, handler: { action in
          self.updateServerSyncSetting(toEnabled: true) { success in
            completion(success)
            settings.userHasSeenFirstTimeSyncMessage = true;
          }
        })
        alertController.addAction(notNowAction)
        alertController.addAction(enableSyncAction)
        alertController.preferredAction = enableSyncAction
        NYPLAlertUtils.presentFromViewControllerOrNil(alertController: alertController, viewController: nil, animated: true, completion: nil)
      } else {
        completion(false)
      }
    }
  }

  /// Ask the server to enable Annotations on the current user account for the
  /// currently selected library. Server will return null, true, or false. Null
  /// assumes the user has never been introduced to the feature ("initialized").
  /// The closure expects "enabled" which is strictly to inform this single client
  /// how to respond based on the server's info.
  /// - Parameters:
  ///   - enabled: whether to enable annotation-syncing or not.
  ///   - completion: if a network request is actually performed, this block
  /// is guaranteed to be called on the Main queue. Otherwise, this is called
  /// on the same thread the function was invoked on.
  class func updateServerSyncSetting(toEnabled enabled: Bool, completion:@escaping (Bool)->()) {
    if (NYPLUserAccount.sharedAccount().hasCredentials() &&
      AccountsManager.shared.currentAccount?.details?.supportsSimplyESync == true) {
      guard let userProfileUrl = URL(string: AccountsManager.shared.currentAccount?.details?.userProfileUrl ?? "") else {
        Log.error(#file, "Could not create user profile URL from string. Abandoning attempt to update sync setting.")
        completion(false)
        return
      }
      let parameters = ["settings": ["simplified:synchronize_annotations": enabled]] as [String : Any]
      syncSettingUrlRequest(userProfileUrl, parameters, 20, { success in
        if !success {
          handleSyncSettingError()
        }
        completion(success)
      })
    }
  }


  /// - Parameter successHandler: Called only if the request succeeds.
  /// Always called on the main thread.
  private class func permissionUrlRequest(successHandler: @escaping (_ initialized: Bool, _ syncIsPermitted: Bool) -> ()) {

    guard let userProfileUrl = URL(string: AccountsManager.shared.currentAccount?.details?.userProfileUrl ?? "") else {
      Log.error(#file, "Failed to create user profile URL from string. Abandoning attempt to retrieve sync setting.")
      return
    }

    var request = URLRequest.init(url: userProfileUrl,
                                  cachePolicy: .reloadIgnoringLocalCacheData,
                                  timeoutInterval: 60)
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
              successHandler(false, false)
            } else {
              successHandler(true, syncSetting as? Bool ?? false)
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
  }

  /// - parameter completion: if a network request is actually performed, this
  /// is guaranteed to be called on the Main queue. Otherwise, this is called
  /// on the same thread the function was invoked on.
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
    let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction.init(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
    NYPLAlertUtils.presentFromViewControllerOrNil(alertController: alert, viewController: nil, animated: true, completion: nil)
  }

  // MARK: - Reading Position

  class func syncReadingPosition(ofBook bookID: String?, toURL url:URL?,
                                 completionHandler: @escaping (_ responseObject: [String:String]?) -> ()) {

    if !syncIsPossibleAndPermitted() {
      completionHandler(nil)
      Log.debug(#file, "Account does not support sync or sync is disabled.")
      return
    }

    guard let url = url, let bookID = bookID else {
      completionHandler(nil)
      Log.error(#file, "Required parameters are nil.")
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
          Log.error(#file, "Response from annotation server could not be serialized.")
          completionHandler(nil)
          return
      }

      guard let first = json["first"] as? [String:AnyObject],
        let items = first["items"] as? [AnyObject] else {
          Log.error(#file, "Missing required key from Annotations response, or no items exist.")
          completionHandler(nil)
          return
      }
      
      for item in items {
        guard let target = item["target"] as? [String:AnyObject],
          let source = target["source"] as? String,
          let motivation = item["motivation"] as? String else {
            completionHandler(nil)
            continue
        }
        
        if source == bookID && motivation == "http://librarysimplified.org/terms/annotation/idling" {
          
          guard let selector = target["selector"] as? [String:AnyObject],
            let serverCFI = selector["value"] as? String else {
              Log.error(#file, "No CFI saved for title on the server.")
              completionHandler(nil)
              return
          }
          
          var responseObject = [serverCFIKey : serverCFI]
          
          if let body = item["body"] as? [String:AnyObject],
            let device = body["http://librarysimplified.org/terms/device"] as? String,
            let time = body["http://librarysimplified.org/terms/time"] as? String {
            responseObject[serverDeviceKey] = device
            responseObject["time"] = time
          }
          completionHandler(responseObject)
          return
        }
      }
      Log.error(#file, "No Annotation Item found for this title.")
      completionHandler(nil)
      return
    }
    dataTask.resume()
  }
  
  class func postReadingPosition(forBook bookID: String, annotationsURL:URL?, cfi: String) {

    if !syncIsPossibleAndPermitted() {
      Log.debug(#file, "Account does not support sync or sync is disabled.")
      return
    }
    // If no specific URL is provided, post to annotation URL provided by OPDS Main Feed.
    let mainFeedAnnotationURL = NYPLConfiguration.mainFeedURL()?.appendingPathComponent("annotations/")
    guard let annotationsURL = annotationsURL ?? mainFeedAnnotationURL else {
        Log.error(#file, "Required parameter was nil.")
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
        "http://librarysimplified.org/terms/device" : NYPLUserAccount.sharedAccount().deviceID
      ]
      ] as [String : Any]
    
    postAnnotation(forBook: bookID, withAnnotationURL: annotationsURL, withParameters: parameters, timeout: nil, queueOffline: true) { (success, id) in
      if success {
        let location = ((parameters["target"] as? [String:Any])?["selector"] as? [String:Any])?["value"] as? String ?? "null"
        Log.debug(#file, "Success: Marked Reading Position To Server: \(location)")
      } else {
        NYPLErrorLogger.logError(withCode: .apiCall,
                                 summary: "Error posting annotation",
                                 metadata: [
                                  "bookID": bookID,
                                  "annotationID": id ?? "N/A",
                                  "annotationURL": annotationsURL])
      }
    }
  }
  
  private class func postAnnotation(forBook bookID: String,
                                    withAnnotationURL url: URL,
                                    withParameters parameters: [String:Any],
                                    timeout: Double?,
                                    queueOffline: Bool,
                                    _ completionHandler: @escaping (_ success: Bool, _ annotationID: String?) -> ()) {

    guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: [.prettyPrinted]) else {
      Log.error(#file, "Network request abandoned. Could not create JSON from given parameters.")
      completionHandler(false, nil)
      return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = jsonData
    setDefaultAnnotationHeaders(forRequest: &request)
    if let timeout = timeout {
      request.timeoutInterval = timeout
    }
    
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in

      if let error = error as NSError? {
        Log.error(#file, "Annotation POST error (nsCode: \(error.code) Description: \(error.localizedDescription))")
        if (NetworkQueue.StatusCodes.contains(error.code)) && (queueOffline == true) {
          self.addToOfflineQueue(bookID, url, parameters)
        }
        completionHandler(false, nil)
        return
      }
      guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
        Log.error(#file, "Annotation POST error: No response received from server")
        completionHandler(false, nil)
        return
      }

      if statusCode == 200 {
        Log.debug(#file, "Annotation POST: Success 200.")
        let serverAnnotationID = annotationID(fromNetworkData: data)
        completionHandler(true, serverAnnotationID)
      } else {
        Log.error(#file, "Annotation POST: Response Error. Status Code: \(statusCode)")
        completionHandler(false, nil)
      }
    }
    task.resume()
  }

  private class func annotationID(fromNetworkData data: Data?) -> String? {

    guard let data = data else {
      Log.error(#file, "No Annotation ID saved: No data received from server.")
      return nil
    }
    guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String:Any] else {
      Log.error(#file, "No Annotation ID saved: JSON could not be created from data.")
      return nil
    }
    if let annotationID = json["id"] as? String {
      return annotationID
    } else {
      Log.error(#file, "No Annotation ID saved: Key/Value not found in JSON response.")
      return nil
    }
  }

  // MARK: - Bookmarks

  // Completion handler will return a nil parameter if there are any failures with
  // the network request, deserialization, or sync permission is not allowed.
  class func getServerBookmarks(forBook bookID:String?, atURL annotationURL:URL?, completionHandler: @escaping (_ bookmarks: [NYPLReadiumBookmark]?) -> ()) {

    if !syncIsPossibleAndPermitted() {
      Log.debug(#file, "Account does not support sync or sync is disabled.")
      completionHandler(nil)
      return
    }

    guard let bookID = bookID, let annotationURL = annotationURL else {
      Log.error(#file, "Required parameter was nil.")
      completionHandler(nil)
      return
    }

    var request = URLRequest.init(url: annotationURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
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
          Log.error(#file, "JSON could not be created from data.")
          completionHandler(nil)
          return
      }

      guard let first = json["first"] as? [String:AnyObject],
        let items = first["items"] as? [AnyObject] else {
          Log.error(#file, "Missing required key from Annotations response, or no items exist.")
          completionHandler(nil)
          return
      }

      var bookmarks = [NYPLReadiumBookmark]()

      for item in items {
        if let bookmark = createBookmark(fromBook: bookID, serverAnnotation: item) {
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

  private class func createBookmark(fromBook bookID: String, serverAnnotation annotation: AnyObject) -> NYPLReadiumBookmark? {

    guard let target = annotation["target"] as? [String:AnyObject],
    let source = target["source"] as? String,
    let annotationID = annotation["id"] as? String,
    let motivation = annotation["motivation"] as? String else {
      Log.error(#file, "Error parsing key/values for target.")
      return nil
    }

    if source == bookID && motivation.contains("bookmarking") {

      guard let selector = target["selector"] as? [String:AnyObject],
        let serverCFI = selector["value"] as? String,
        let body = annotation["body"] as? [String:AnyObject] else {
          Log.error(#file, "ServerCFI could not be parsed.")
          return nil
      }

      guard let device = body["http://librarysimplified.org/terms/device"] as? String,
      let time = body["http://librarysimplified.org/terms/time"] as? String,
      let progressWithinChapter = (body["http://librarysimplified.org/terms/progressWithinChapter"] as? NSNumber)?.floatValue,
      let progressWithinBook = (body["http://librarysimplified.org/terms/progressWithinBook"] as? NSNumber)?.floatValue else {
        Log.error(#file, "Error reading required bookmark key/values from body")
        return nil
      }
      let chapter = body["http://librarysimplified.org/terms/chapter"] as? String

      guard let data = serverCFI.data(using: String.Encoding.utf8),
        let serverCfiJsonObject = (try? JSONSerialization.jsonObject(with: data,
          options: [])) as? [String: Any],
        let serverIdrefString = serverCfiJsonObject["idref"] as? String
         else {
          Log.error(#file, "Error serializing serverCFI into JSON.")
          return nil
      }
      
      var serverCfiString: String?
      
      if let serverCfiJson = serverCfiJsonObject["contentCFI"] as? String {
        serverCfiString = serverCfiJson
      }
      
      return NYPLReadiumBookmark(annotationId: annotationID,
                                 contentCFI: serverCfiString,
                                 idref: serverIdrefString,
                                 chapter: chapter,
                                 page: nil,
                                 location: serverCFI,
                                 progressWithinChapter: progressWithinChapter,
                                 progressWithinBook: progressWithinBook,
                                 time:time,
                                 device:device)

    } else {
      Log.error(#file, "Bookmark not created from Annotation Element. 'Motivation' Type: \(motivation)")
    }
    return nil
  }

  class func deleteBookmarks(_ bookmarks: [NYPLReadiumBookmark]) {

    if !syncIsPossibleAndPermitted() {
      Log.debug(#file, "Account does not support sync or sync is disabled.")
      return
    }

    for localBookmark in bookmarks {
      if let annotationID = localBookmark.annotationId {
        deleteBookmark(annotationId: annotationID) { success in
          if success {
            Log.debug(#file, "Server bookmark deleted: \(annotationID)")
          } else {
            Log.error(#file, "Bookmark not deleted from server. Moving on: \(annotationID)")
          }
        }
      }
    }
  }

  class func deleteBookmark(annotationId: String,
                            completionHandler: @escaping (_ success: Bool) -> ()) {

    if !syncIsPossibleAndPermitted() {
      Log.debug(#file, "Account does not support sync or sync is disabled.")
      completionHandler(false)
      return
    }

    guard let url = URL(string: annotationId) else {
      Log.error(#file, "Invalid URL from Annotation ID")
      completionHandler(false)
      return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "DELETE"
    setDefaultAnnotationHeaders(forRequest: &request)
    request.timeoutInterval = 20.0
    
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
      let response = response as? HTTPURLResponse
      if response?.statusCode == 200 {
        Log.info(#file, "200: DELETE bookmark success")
        completionHandler(true)
      } else if let code = response?.statusCode {
        Log.error(#file, "DELETE bookmark failed with server response code: \(code)")
        completionHandler(false)
      } else {
        guard let error = error as NSError? else { return }
        Log.error(#file, "DELETE bookmark Request Failed with Error Code: \(error.code). Description: \(error.localizedDescription)")
        completionHandler(false)
      }
    }
    task.resume()
  }


  // Method is called when the SyncManager is syncing bookmarks
  // If an existing local bookmark is missing an annotationID, assume it still needs to be uploaded.
  class func uploadLocalBookmarks(_ bookmarks: [NYPLReadiumBookmark],
                                  forBook bookID: String,
                                  completion: @escaping ([NYPLReadiumBookmark], [NYPLReadiumBookmark])->()) {

    if !syncIsPossibleAndPermitted() {
      Log.debug(#file, "Account does not support sync or sync is disabled.")
      return
    }

    Log.debug(#file, "Begin task of uploading local bookmarks, count: \(bookmarks.count).")
    let uploadGroup = DispatchGroup()
    var bookmarksFailedToUpdate = [NYPLReadiumBookmark]()
    var bookmarksUpdated = [NYPLReadiumBookmark]()

    for localBookmark in bookmarks {
      if localBookmark.annotationId == nil {
        uploadGroup.enter()
        postBookmark(forBook: bookID, toURL: nil, bookmark: localBookmark, completionHandler: { serverID in
          if let ID = serverID {
            localBookmark.annotationId = ID
            bookmarksUpdated.append(localBookmark)
          } else {
            Log.error(#file, "Local Bookmark not uploaded: \(localBookmark)")
            bookmarksFailedToUpdate.append(localBookmark)
          }
          uploadGroup.leave()
        })
      }
    }

    uploadGroup.notify(queue: DispatchQueue.main) {
      Log.debug(#file, "Finished task of uploading local bookmarks.")
      completion(bookmarksUpdated, bookmarksFailedToUpdate)
    }
  }

  class func postBookmark(forBook bookID: String,
                          toURL annotationsURL: URL?,
                          bookmark: NYPLReadiumBookmark,
                          completionHandler: @escaping (_ serverID: String?) -> ())
  {
    if !syncIsPossibleAndPermitted() {
      Log.debug(#file, "Account does not support sync or sync is disabled.")
      completionHandler(nil)
      return
    }
    let mainFeedAnnotationURL = NYPLConfiguration.mainFeedURL()?.appendingPathComponent("annotations/")
    guard let annotationsURL = annotationsURL ?? mainFeedAnnotationURL else {
        Log.error(#file, "Required parameter was nil.")
        completionHandler(nil)
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
          "value": bookmark.location
        ]
      ],
      "body": [
        "http://librarysimplified.org/terms/time" : bookmark.time,
        "http://librarysimplified.org/terms/device" : bookmark.device ?? "",
        "http://librarysimplified.org/terms/chapter" : bookmark.chapter ?? "",
        "http://librarysimplified.org/terms/progressWithinChapter" : bookmark.progressWithinChapter,
        "http://librarysimplified.org/terms/progressWithinBook" : bookmark.progressWithinBook,
      ]
      ] as [String : Any]

    postAnnotation(forBook: bookID, withAnnotationURL: annotationsURL, withParameters: parameters, timeout: 20.0, queueOffline: false) { (success, id) in
      completionHandler(id)
    }
  }

  // MARK: -

  /// Annotation-syncing is possible only if the given `account` is signed-in
  /// and if the currently selected library supports it.
  class func syncIsPossible(_ account: NYPLUserAccount) -> Bool {
    let library = AccountsManager.shared.currentAccount
    return account.hasCredentials() && library?.details?.supportsSimplyESync == true
  }

  class func syncIsPossibleAndPermitted() -> Bool {
    let acct = AccountsManager.shared.currentAccount
    return syncIsPossible(NYPLUserAccount.sharedAccount()) && acct?.details?.syncPermissionGranted == true
  }

    @objc class func addingDefaultAnnotationHeaders(to request: URLRequest) -> URLRequest {
        var request = request
        for (headerKey, headerValue) in NYPLAnnotations.headers {
            request.setValue(headerValue, forHTTPHeaderField: headerKey)
        }
        return request
    }

  class func setDefaultAnnotationHeaders(forRequest request: inout URLRequest) {
      for (headerKey, headerValue) in NYPLAnnotations.headers {
          request.setValue(headerValue, forHTTPHeaderField: headerKey)
      }
  }

  class var headers: [String:String] {
    if let barcode = NYPLUserAccount.sharedAccount().barcode, let pin = NYPLUserAccount.sharedAccount().PIN {
      let authenticationString = "\(barcode):\(pin)"
      if let authenticationData = authenticationString.data(using: String.Encoding.ascii) {
        let authenticationValue = "Basic \(authenticationData.base64EncodedString(options: .lineLength64Characters))"
        return ["Authorization" : "\(authenticationValue)",
                "Content-Type" : "application/json"]
      } else {
        Log.error(#file, "Error formatting auth headers.")
      }
    } else if let authToken = NYPLUserAccount.sharedAccount().authToken {
        let authenticationValue = "Bearer \(authToken)"
        return ["Authorization" : "\(authenticationValue)",
            "Content-Type" : "application/json"]
    } else {
      Log.error(#file, "Attempted to create authorization header with neither an oauth token nor a barcode and pin pair.")
    }
    return ["Authorization" : "",
            "Content-Type" : "application/json"]
  }

  private class func addToOfflineQueue(_ bookID: String?, _ url: URL, _ parameters: [String:Any]) {
    let libraryID = AccountsManager.shared.currentAccount?.uuid ?? ""
    let parameterData = try? JSONSerialization.data(withJSONObject: parameters, options: [.prettyPrinted])
    NetworkQueue.shared().addRequest(libraryID, bookID, url, .POST, parameterData, headers)
  }
}
