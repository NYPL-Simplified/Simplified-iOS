import UIKit
import R2Shared
import NYPLUtilities
#if FEATURE_AUDIOBOOKS
import NYPLAudiobookToolkit
#endif

protocol NYPLAnnotationSettings: AnyObject {
  var userHasSeenFirstTimeSyncMessage: Bool {get set}
}

protocol NYPLServerSyncUpdating: AnyObject {
  func updateServerSyncSetting(toEnabled enabled: Bool,
                               completion:@escaping (Bool)->())
}

protocol NYPLServerSyncChecking: AnyObject {
  func checkServerSyncStatus(settings: NYPLAnnotationSettings,
                             syncPermissionGranted: Bool,
                             syncSupportedCompletion: @escaping (_ enableSync: Bool,
                                                                 _ error: Error?) -> ())
  func syncIsPossibleAndPermitted() -> Bool
}

protocol NYPLLastReadPositionSupportAPI: AnyObject {
  func syncIsPossibleAndPermitted() -> Bool

  func syncReadingPosition<T: NYPLBookmark>(of type: T.Type,
                                            forBook bookID: String?,
                                            publication: Publication?,
                                            toURL url: URL?,
                                            completion: @escaping (_ readPos: T?) -> ())

  func postReadingPosition(forBook bookID: String, selectorValue: String)

}

protocol NYPLAnnotationSyncing: NYPLServerSyncUpdating, NYPLServerSyncChecking, NYPLLastReadPositionSupportAPI {

  // Bookmarks

  func getServerBookmarks<T: NYPLBookmark>(of type: T.Type,
                                           forBook bookID:String?,
                                           publication: Publication?,
                                           atURL annotationURL:URL?,
                                           completion: @escaping (_ bookmarks: [T]?) -> ())

  func deleteBookmarks(_ bookmarks: [NYPLBookmark])

  func deleteBookmark(annotationId: String,
                      completionHandler: @escaping (_ success: Bool) -> ())

  func uploadLocalBookmarks<T: NYPLBookmark>(_ bookmarks: [T],
                                             forBook bookID: String,
                                             completion: @escaping ([T], [T])->())

  func postBookmark(_ bookmark: NYPLBookmark,
                    forBookID bookID: String,
                    completion: @escaping (_ serverID: String?) -> ())
}

//------------------------------------------------------------------------------
// MARK: -

final class NYPLAnnotations: NSObject, NYPLAnnotationSyncing {

  let failFastExecutor: NYPLNetworkExecutor

  override init() {
    failFastExecutor = NYPLNetworkExecutor(
      credentialsSource: NYPLUserAccount.sharedAccount(),
      cachingStrategy: .ephemeral,
      waitsForConnectivity: false)

    super.init()
  }

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
  ///   - settings: The interface to the settings related to annotations.
  ///   - syncPermissionGranted: Whether the permission to sync bookmarks was
  ///   granted or not.
  ///   - syncSupportedCompletion: Handler always called at the end of the
  ///   process, unless sync is not supported by the current library.
  func checkServerSyncStatus(settings: NYPLAnnotationSettings,
                             syncPermissionGranted: Bool,
                             syncSupportedCompletion: @escaping (_ enableSync: Bool,
                                                                 _ error: Error?) -> ()) {
    guard syncIsPossible() else {
      Log.info(#function, "Account does not satisfy conditions for sync setting request.")
      return
    }

    if settings.userHasSeenFirstTimeSyncMessage && !syncPermissionGranted {
      syncSupportedCompletion(false, nil)
      return
    }

    self.fetchSyncStatus { (initialized, syncIsPermitted, error) in

      guard error == nil else {
        NYPLErrorLogger.logError(error,
                                 summary: "Unable to fetch current bookmark sync status")
        syncSupportedCompletion(false, error)
        return
      }

      if (initialized && syncIsPermitted) {
        Log.info(#function, "Sync has already been enabled on the server. Enabling in UserDefaults as well.")
        syncSupportedCompletion(true, nil)
        settings.userHasSeenFirstTimeSyncMessage = true;
        return
      }

      if (!initialized && settings.userHasSeenFirstTimeSyncMessage == false) {
        Log.info(#function, "Sync has never been initialized for the patron. Showing alert flow.")
        NYPLMainThreadRun.asyncIfNeeded {
#if OPENEBOOKS
          let title = "Open eBooks Sync"
#else
          let title = "SimplyE Sync"
#endif
          let message = "Enable sync to save your reading position and bookmarks to your other devices.\n\nYou can change this any time in Settings."
          let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
          let notNowAction = UIAlertAction(title: "Not Now", style: .default) { action in
            syncSupportedCompletion(false, nil)
            settings.userHasSeenFirstTimeSyncMessage = true;
          }
          let enableSyncAction = UIAlertAction(title: "Enable Sync", style: .default) { action in
            self.updateServerSyncSetting(toEnabled: true) { success in
              syncSupportedCompletion(success, nil)
              settings.userHasSeenFirstTimeSyncMessage = true;
            }
          }
          alertController.addAction(notNowAction)
          alertController.addAction(enableSyncAction)
          alertController.preferredAction = enableSyncAction
          NYPLAlertUtils.presentFromViewControllerOrNil(alertController: alertController, viewController: nil, animated: true, completion: nil)
        }
      } else {
        syncSupportedCompletion(false, nil)
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
  func updateServerSyncSetting(toEnabled enabled: Bool, completion:@escaping (Bool)->()) {
    if (NYPLUserAccount.sharedAccount().hasCredentials() &&
        AccountsManager.shared.currentAccount?.details?.supportsSimplyESync == true) {
      guard let userProfileUrl = URL(string: AccountsManager.shared.currentAccount?.details?.userProfileUrl ?? "") else {
        Log.error(#file, "Could not create user profile URL from string. Abandoning attempt to update sync setting.")
        completion(false)
        return
      }
      let parameters = ["settings": ["simplified:synchronize_annotations": enabled]] as [String : Any]
      NYPLAnnotations.updateSyncSettings(at: userProfileUrl, parameters, { success in
        if !success {
          NYPLAnnotations.handleSyncSettingError()
        }
        completion(success)
      })
    }
  }

  private func fetchSyncStatus(completion: @escaping (_ initialized: Bool,
                                                      _ syncIsPermitted: Bool,
                                                      _ error: Error?) -> ()) {
    guard let userProfileUrl = URL(string: AccountsManager.shared.currentAccount?.details?.userProfileUrl ?? "") else {
      Log.error(#file, "Failed to create user profile URL from string. Abandoning attempt to retrieve sync setting.")
      return
    }

    NYPLNetworkExecutor.shared.GET(userProfileUrl, cachePolicy: .reloadIgnoringCacheData) { result in
      switch result {
      case .success(let data, _):
        do {
          let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]

          if let settings = json?["settings"] as? [String: Any],
             let syncSetting = settings["simplified:synchronize_annotations"] {
            if syncSetting is NSNull {
              completion(false, false, nil)
            } else {
              completion(true, syncSetting as? Bool ?? false, nil)
            }
          } else {
            let error = NSError(domain: "Error finding sync-setting key/value",
                                code: NYPLErrorCode.parseFail.rawValue,
                                userInfo: ["jsonData": json ?? "N/A"])
            Log.error(#function, "\(error)")
            completion(false, false, error)
          }
        } catch {
          completion(false, false, error)
        }
      case .failure(let error, let response):
        let httpStatus = (response as? HTTPURLResponse)?.statusCode ?? -1
        Log.error(#file, "Error fetching annotations permissions: \(httpStatus); error: \(error)")
        completion(false, false, error)
      }
    }
  }

  /// - parameter completion: if a network request is actually performed, this
  /// is guaranteed to be called on the Main queue. Otherwise, this is called
  /// on the same thread the function was invoked on.
  private class func updateSyncSettings(at url: URL,
                                        _ parameters: [String:Any],
                                        _ completion: @escaping (Bool)->()) {
    guard let jsonData = NYPLAnnotations.makeSubmissionData(fromRepresentation: parameters) else {
      Log.error(#file, "Network request abandoned. Could not create JSON from given parameters.")
      completion(false)
      return
    }

    NYPLNetworkExecutor.shared.PUT(url,
                                   additionalHeaders: ["Content-Type": "vnd.librarysimplified/user-profile+json"],
                                   httpBody: jsonData) { data, response, error in
      if let error = error as NSError? {
        let httpStatus = (response as? HTTPURLResponse)?.statusCode ?? -1
        Log.error(#file, "Error updating sync settings, server returned: \(httpStatus)")
        if NetworkQueue.StatusCodes.contains(error.code) {
          NYPLAnnotations.addRequestToOfflineQueue(httpMethod: .PUT,
                                                   url: url,
                                                   parameters: parameters)
        }
        completion(false)
        return
      }

      completion(true)
    }
  }

  private class func handleSyncSettingError() {
    NYPLMainThreadRun.asyncIfNeeded {
      let title = NSLocalizedString("Error Changing Sync Setting", comment: "")
      let message = NSLocalizedString("There was a problem contacting the server.\nPlease make sure you are connected to the internet, or try again later.", comment: "")
      let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
      NYPLAlertUtils.presentFromViewControllerOrNil(alertController: alert, viewController: nil, animated: true, completion: nil)
    }
  }

  // MARK: - Reading Position

  /// Reads the current reading position from the server, parses the response
  /// and returns the result to the `completionHandler`.
  func syncReadingPosition<T: NYPLBookmark>(of type: T.Type,
                                            forBook bookID: String?,
                                            publication: Publication?,
                                            toURL url: URL?,
                                            completion: @escaping (_ readPos: T?) -> ()) {

    guard syncIsPossibleAndPermitted() else {
      Log.info(#file, "Library account does not support sync or sync is disabled by user.")
      completion(nil)
      return
    }

    guard let url = url, let bookID = bookID else {
      Log.error(#file, "Required parameters are nil.")
      completion(nil)
      return
    }

    _ = failFastExecutor.GET(url,
                             cachePolicy: .reloadIgnoringLocalCacheData) { data, _, error in
      let bookmarks: [T]? = NYPLAnnotations
        .parseAnnotationsResponse(data,
                                  of: T.self,
                                  error: error,
                                  motivation: .readingProgress,
                                  publication: publication,
                                  bookID: bookID)
      let readPos = bookmarks?.first
      completion(readPos)
    }
  }

  func postReadingPosition(forBook bookID: String, selectorValue: String) {
    // Format annotation for submission to server according to spec
    let bookmark = NYPLBookmarkSpec(time: Date(),
                                    device: NYPLUserAccount.sharedAccount().deviceID ?? "",
                                    motivation: .readingProgress,
                                    bookID: bookID,
                                    selectorValue: selectorValue)
    let parameters = bookmark.dictionaryForJSONSerialization()

    guard syncIsPossibleAndPermitted() else {
      Log.info(#file, "Library account does not support sync or sync is disabled by user.")
      return
    }

    postAnnotation(forBook: bookID,
                   withParameters: parameters,
                   queueOffline: true) { result in
      if case let .failure(err) = result {
        NYPLErrorLogger.logError(err,
                                 summary: "Error posting reading progress",
                                 metadata: ["bookID": bookID])
        return
      }
      Log.debug(#file, "Successfully saved Reading Position to server: \(selectorValue)")
    }
  }

  // MARK: - Bookmarks

  // Completion handler will return a nil parameter if there are any failures with
  // the network request, deserialization, or sync permission is not allowed.
  func getServerBookmarks<T: NYPLBookmark>(of type: T.Type,
                                           forBook bookID:String?,
                                           publication: Publication?,
                                           atURL annotationURL:URL?,
                                           completion: @escaping (_ bookmarks: [T]?) -> ()) {

    guard syncIsPossibleAndPermitted() else {
      Log.info(#file, "Library account does not support sync or sync is disabled by user.")
      completion(nil)
      return
    }

    guard let bookID = bookID, let annotationURL = annotationURL else {
      Log.error(#file, "Required parameter was nil.")
      completion(nil)
      return
    }

    NYPLNetworkExecutor.shared.GET(annotationURL, cachePolicy: .reloadIgnoringLocalCacheData) { data, _, error in
      let bookmarks: [T]? = NYPLAnnotations
        .parseAnnotationsResponse(data,
                                  of: T.self,
                                  error: error,
                                  motivation: .bookmark,
                                  publication: publication,
                                  bookID: bookID)
      completion(bookmarks)
    }
  }

  func deleteBookmarks(_ bookmarks: [NYPLBookmark]) {

    if !syncIsPossibleAndPermitted() {
      Log.info(#file, "Library account does not support sync or sync is disabled by user.")
      return
    }

    for localBookmark in bookmarks {
      if let annotationID = localBookmark.annotationId {
        deleteBookmark(annotationId: annotationID) { success in
          if success {
            Log.info(#file, "Server bookmark deleted: \(annotationID)")
          } else {
            Log.error(#file, "Bookmark not deleted from server. Moving on: \(annotationID)")
          }
        }
      }
    }
  }

  func deleteBookmark(annotationId: String,
                      completionHandler: @escaping (_ success: Bool) -> ()) {

    if !syncIsPossibleAndPermitted() {
      Log.info(#file, "Library account does not support sync or sync is disabled by user.")
      completionHandler(false)
      return
    }

    guard let url = URL(string: annotationId) else {
      Log.error(#file, "Invalid URL from Annotation ID")
      completionHandler(false)
      return
    }

    NYPLNetworkExecutor.shared.DELETE(url) { result in
      switch result {
      case .success(_, _):
        Log.info(#file, "200: DELETE bookmark success")
        completionHandler(true)
      case .failure(let error, let response):
        NYPLErrorLogger.logError(error,
                                 summary: "NYPLAnnotations::deleteBookmark error",
                                 metadata: ["annotationId": annotationId,
                                            "DELETE url": url,
                                            "response": response ?? ""])
        completionHandler(false)
      }
    }
  }

  // Method is called when the SyncManager is syncing bookmarks
  // If an existing local bookmark is missing an annotationID, assume it still needs to be uploaded.
  func uploadLocalBookmarks<T: NYPLBookmark>(_ bookmarks: [T],
                                             forBook bookID: String,
                                             completion: @escaping ([T], [T])->()) {

    if !syncIsPossibleAndPermitted() {
      Log.info(#file, "Library account does not support sync or sync is disabled by user.")
      return
    }

    Log.debug(#file, "Begin task of uploading local bookmarks, count: \(bookmarks.count).")
    let uploadGroup = DispatchGroup()
    var bookmarksFailedToUpdate = [T]()
    var bookmarksUpdated = [T]()

    for localBookmark in bookmarks {
      if localBookmark.annotationId == nil {
        uploadGroup.enter()
        postBookmark(localBookmark, forBookID: bookID) { serverID in
          if let ID = serverID {
            var newBookmark = localBookmark
            newBookmark.annotationId = ID
            bookmarksUpdated.append(newBookmark)
          } else {
            Log.error(#file, "Local Bookmark not uploaded: \(localBookmark)")
            bookmarksFailedToUpdate.append(localBookmark)
          }
          uploadGroup.leave()
        }
      }
    }

    uploadGroup.notify(queue: DispatchQueue.main) {
      Log.debug(#file, "Finished task of uploading local bookmarks.")
      completion(bookmarksUpdated, bookmarksFailedToUpdate)
    }
  }

  /// Posts an explicit bookmark to the server.
  ///
  /// To post a reading progress annotation,
  /// use `postReadingPosition(forBook:selectorValue:)`.
  ///
  /// - Parameters:
  ///   - bookmark: The bookmark to save to the server.
  ///   - bookID: The book ID the bookmark refers to.
  ///   - completion: Always called at the end of the api call.
  func postBookmark(_ bookmark: NYPLBookmark,
                    forBookID bookID: String,
                    completion: @escaping (_ serverID: String?) -> ()) {

    let serializableBookmark = bookmark
      .serializableRepresentation(forMotivation: .bookmark,
                                  bookID: bookID)

    guard syncIsPossibleAndPermitted() else {
      Log.info(#file, "Library account does not support sync or sync is disabled by user.")
      completion(nil)
      return
    }

    postAnnotation(forBook: bookID,
                   withParameters: serializableBookmark,
                   queueOffline: false) { result in
      switch result {
      case .success(let id):
        completion(id)
      case .failure(let err):
        NYPLErrorLogger.logError(err,
                                 summary: "NYPLAnnotations::postBookmark error",
                                 metadata: ["bookID": bookID])
        completion(nil)
      }
    }
  }

  // MARK: - Helpers / Private methods

  private class func parseAnnotationsResponse<T: NYPLBookmark>(_ data: Data?,
                                                               of type: T.Type,
                                                               error: Error?,
                                                               motivation: NYPLBookmarkSpec.Motivation,
                                                               publication: Publication?,
                                                               bookID: String) -> [T]? {
    let metadata: [String: Any] = ["bookID": bookID,
                                   "motivation": motivation]
    if let error = error as NSError? {
      NYPLErrorLogger.logError(error,
                               summary: "NYPLAnnotations::parseAnnotationsResponse error",
                               metadata: metadata)
      return nil
    }

    guard let data = data,
          let jsonObject = try? JSONSerialization.jsonObject(with: data,
                                                             options: []),
          let json = jsonObject as? [String: Any] else {
      NYPLErrorLogger.logError(withCode: .serializationFail,
                               summary: "NYPLAnnotations::parseAnnotationsResponse error",
                               metadata: metadata)
      return nil
    }

    guard let first = json["first"] as? [String: Any],
          let items = first["items"] as? [[String: Any]] else {
      NYPLErrorLogger.logError(withCode: .noData,
                               summary: "NYPLAnnotations::parseAnnotationsResponse error",
                               metadata: metadata)
      return nil
    }

    var bookmarks = [T]()
    
#if FEATURE_AUDIOBOOKS
    if type == NYPLAudiobookBookmark.self {
      bookmarks = items.compactMap{
        /// Given NYPLAudiobookToolkit has no access to classes in Simplified-iOS repo,
        /// we pass the NYPLBookmarkFactory class to NYPLAudiobookBookmarkFactory through a protocol,
        /// in order to allow NYPLAudiobookBookmarkFactory to access the parser function in NYPLBookmarkFactory.
        NYPLAudiobookBookmarkFactory.make(fromServerAnnotation: $0,
                                          selectorValueParser: NYPLBookmarkFactory.self,
                                          annotationType: motivation,
                                          bookID: bookID) as? T
      }
      
      return bookmarks
    }
#endif
    
    bookmarks = items.compactMap{
      NYPLReadiumBookmarkFactory.make(fromServerAnnotation: $0,
                                      annotationType: motivation,
                                      bookID: bookID,
                                      publication: publication) as? T
    }
    
    return bookmarks
  }

  /// Serializes the `parameters` into JSON and POSTs them to the server.
  ///
  /// - Note: Does not log error reports to Crashlytics. That responsibility is
  /// left to the caller.
  private func postAnnotation(forBook bookID: String,
                              withParameters parameters: [String: Any],
                              queueOffline: Bool,
                              _ completion: @escaping (_ result: Result<String?, Error>) -> ()) {

    guard let annotationsURL = NYPLAnnotations.annotationsURL else {
      let err = NSError(domain: "Error posting annotation",
                        code: NYPLErrorCode.appLogicInconsistency.rawValue,
                        userInfo: ["Reason": "annotationsURL is nil"])
      completion(.failure(err))
      return
    }

    guard let jsonData = NYPLAnnotations.makeSubmissionData(fromRepresentation: parameters) else {
      let err = NSError(domain: "Error posting annotation",
                        code: NYPLErrorCode.serializationFail.rawValue,
                        userInfo: ["Reason": "Could not create JSON body from input params",
                                   "Serializable annotation params": parameters])
      completion(.failure(err))
      return
    }

    NYPLNetworkExecutor.shared.POST(annotationsURL,
                                    additionalHeaders: ["Content-Type" : "application/json"],
                                    httpBody: jsonData) { result in
      switch result {
      case .success(let data, _):
        Log.info(#file, "Annotation POST for bookID \(bookID): Success 200.")
        let serverAnnotationID = NYPLAnnotations.annotationID(fromNetworkData: data)
        completion(.success(serverAnnotationID))
      case .failure(let error, _):
        let err = error as NSError
        Log.error(#file, "Annotation POST for bookID \(bookID): Error (nsCode: \(err.code) Description: \(err.localizedDescription))")
        if NetworkQueue.StatusCodes.contains(err.code) && queueOffline {
          NYPLAnnotations.addRequestToOfflineQueue(httpMethod: .POST,
                                                   url: annotationsURL,
                                                   bookID: bookID,
                                                   parameters: parameters)
        }
        completion(.failure(err))
      }
    }
  }

  private class func annotationID(fromNetworkData data: Data?) -> String? {
    guard let data = data else {
      Log.error(#file, "No Annotation ID saved: No data received from server.")
      return nil
    }
    guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] else {
      Log.error(#file, "No Annotation ID saved: JSON could not be created from data.")
      return nil
    }
    guard let annotationID = json[NYPLBookmarkSpec.Id.key] as? String else {
      Log.error(#file, "No Annotation ID saved: Key/Value not found in JSON response.")
      return nil
    }

    return annotationID
  }

  /// Annotation-syncing is possible only if the current user account is signed-in
  /// and if the currently selected library supports it.
  private func syncIsPossible() -> Bool {
    let library = AccountsManager.shared.currentAccount
    let userAccount = NYPLUserAccount.sharedAccount()
    return userAccount.hasCredentials() && library?.details?.supportsSimplyESync == true
  }

  func syncIsPossibleAndPermitted() -> Bool {
    let library = AccountsManager.shared.currentAccount
    return syncIsPossible() && library?.details?.syncPermissionGranted == true
  }

  static var annotationsURL: URL? {
    return NYPLConfiguration.mainFeedURL?.appendingPathComponent("annotations/")
  }

  class func makeSubmissionData(fromRepresentation dict: [String: Any]) -> Data? {
    return try? JSONSerialization.data(withJSONObject: dict,
                                       options: [.prettyPrinted])
  }

  private class func addRequestToOfflineQueue(httpMethod: NetworkQueue.HTTPMethodType,
                                              url: URL,
                                              bookID: String? = nil,
                                              parameters: [String:Any]) {
    let libraryID = AccountsManager.shared.currentAccount?.uuid ?? ""
    let parameterData = makeSubmissionData(fromRepresentation: parameters)
    NetworkQueue.shared.addRequest(libraryID, bookID, url, httpMethod, parameterData)
  }
}

extension NYPLAnnotations {
  class func test_parseAnnotationsResponse(_ data: Data?,
                                           error: Error?,
                                           motivation: NYPLBookmarkSpec.Motivation,
                                           publication: Publication?,
                                           bookID: String) -> [NYPLReadiumBookmark]? {
    parseAnnotationsResponse(data, of: NYPLReadiumBookmark.self, error: error, motivation: motivation,
                             publication: publication, bookID: bookID)
  }
}
