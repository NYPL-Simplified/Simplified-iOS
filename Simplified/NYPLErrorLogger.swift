//
//  SimplyE
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation
import Firebase

let NYPLSimplyEDomain = "org.nypl.labs.SimplyE"
fileprivate let nullString = "null"

@objc enum NYPLSeverity: NSInteger {
  case error, warning, info

  func stringValue() -> String {
    switch self {
    case .error: return "error"
    case .warning: return "warning"
    case .info: return "info"
    }
  }
}

@objc enum NYPLErrorCode: Int {
  case ignore = 0

  // low-level / system related
  case fileSystemFail = 1

  // generic app related
  case appLaunch = 100
  case invalidURLSession = 101
  case apiCall = 102
  case genericErrorMsgDisplayed = 103

  // book registry
  case nilBookIdentifier = 200 // caused by book registry, downloads
  case nilCFI = 201
  case missingBookFile = 202
  case unknownBookState = 203

  // sign in/out/up
  case invalidLicensor = 300
  case deAuthFail = 301
  case barcodeException = 302
  case remoteLoginError = 303
  case userProfileDocFail = 305
  case nilSignUpURL = 306
  case adeptAuthFail = 307

  /// Deprecated: don't use
  case nilAccount = 304

  // audiobooks
  case audiobookUserEvent = 400
  case audiobookCorrupted = 401

  // ereader
  case deleteBookmarkFail = 500

  // Parse failure
  case parseProfileDataCorrupted = 600
  case parseProfileTypeMismatch = 601
  case parseProfileValueNotFound = 602
  case parseProfileKeyNotFound = 603
  case feedParseFail = 604
  case opdsFeedParseFail = 605

  // account management
  case authDocLoadFail = 700

  // feeds
  case opdsFeedNoData = 800
}

@objcMembers class NYPLErrorLogger : NSObject {
  class func configureCrashAnalytics() {
    FirebaseApp.configure()

    let deviceID = UIDevice.current.identifierForVendor
    Crashlytics.sharedInstance().setObjectValue(deviceID, forKey: "NYPLDeviceID")
  }

  class func setUserID(_ userID: String?) {
    if let userIDmd5 = userID?.md5hex() {
      Crashlytics.sharedInstance().setUserIdentifier(userIDmd5)
    } else {
      Crashlytics.sharedInstance().setUserIdentifier(nil)
    }
  }

  /// Broad areas providing some kind of operating context for error reporting.
  /// These are meant to be related to the code base more than functionality,
  /// (e.g. an error related to audiobooks may happen in different classes)
  /// although the two things may obviously overlap.
  enum Context: String {
    case accountManagement
    case audiobooks
    case bookDownload
    case catalog
    case ereader
    case infrastructure
    case myBooks
    case opds
    case signIn
    case signOut
    case signUp
    case errorHandling
  }

  // MARK:- Generic helpers

  /**
   Helper method for other logging functions that adds relevant account info
   to our crash reporting system.
   - parameter metadata: report metadata dictionary
   */
  private class func addAccountInfoToMetadata(_ metadata: inout [AnyHashable : Any]) {
    metadata["currentAccountName"] = AccountsManager.shared.currentAccount?.name ?? nullString
    metadata["currentAccountId"] = AccountsManager.shared.currentAccountId ?? nullString
    metadata["currentAccountSet"] = AccountsManager.shared.accountSet
    metadata["numAccounts"] = AccountsManager.shared.accounts().count
  }

  /// Creates a dictionary with information to be logged in relation to an event.
  /// - Parameters:
  ///   - severity: How severe the event is.
  ///   - message: An optional message.
  ///   - context: Page/VC name or anything that can help identify the in-code location where the error occurred.
  ///   - metadata: Any additional metadata.
  private class func additionalInfo(severity: NYPLSeverity,
                                    message: String? = nil,
                                    context: String? = nil,
                                    metadata: [AnyHashable: Any]? = nil) -> [String: Any] {
    var dict: [String: Any] = ["severity": severity.stringValue()]
    if let message = message {
      dict["message"] = message
    }
    if let context = context {
      dict["context"] = context
    }
    if let metadata = metadata {
      dict["metadata"] = metadata
    }
    return dict
  }

  // MARK:- Error Logging

  /// Reports an error.
  /// - Parameters:
  ///   - error: Any originating error that occurred.
  ///   - message: A string for further context.
  class func logError(_ error: Error, message: String? = nil) {
    logError(error, code: .ignore, message: message)
  }


  /// Reports an error situation.
  /// - Parameters:
  ///   - code: A code identifying the error situation. Searchable in
  ///   Crashlytics UI.
  ///   - context: Choose from `Context` enum or provide a string that can
  ///   be used to group similar errors. This will be the top line (searchable)
  ///   in Crashlytics UI.
  ///   - message: A string for further context.
  class func logError(withCode code: NYPLErrorCode,
                      context: String,
                      message: String? = nil) {
    logError(nil, code: code, context: context, message: message)
  }

  /**
    Report when there's a null book identifier
    @param book book
    @param identifier book ID
    @param title book title
    @return
   */
  class func logUnexpectedNilIdentifier(_ identifier: String?, book: NYPLBook?) {
    var metadata = [AnyHashable : Any]()
    metadata["incomingIdentifierString"] = identifier ?? nullString
    metadata["bookTitle"] = book?.title ?? nullString
    metadata["revokeLink"] = book?.revokeURL?.absoluteString ?? nullString
    addAccountInfoToMetadata(&metadata)

    let userInfo = additionalInfo(
      severity: .warning,
      message: "The book identifier was unexpectedly nil when attempting to return.",
      metadata: metadata)
    let err = NSError(domain: Context.myBooks.rawValue,
                      code: NYPLErrorCode.nilBookIdentifier.rawValue,
                      userInfo: userInfo)

    Crashlytics.sharedInstance().recordError(err)
  }
  
  /**
    Report when there's an error copying the book from RMSDK to app storage
    @param book target book
    @return
   */
  class func logMissingFileURLAfterDownloadingBook(_ book: NYPLBook?,
                                                   message: String) {
    var metadata = [AnyHashable : Any]()
    metadata["bookIdentifier"] = book?.identifier ?? nullString
    metadata["bookTitle"] = book?.title ?? nullString
    addAccountInfoToMetadata(&metadata)

    let userInfo = additionalInfo(
      severity: .warning,
      message: message,
      metadata: metadata)
    let err = NSError(domain: Context.bookDownload.rawValue,
                      code: NYPLErrorCode.missingBookFile.rawValue,
                      userInfo: userInfo)

    Crashlytics.sharedInstance().recordError(err)
  }
  
  /**
    Report when there's a null CFI
    @param location CFI location in the EPUB
    @param locationDictionary
    @param bookId id of the book
    @param title name of the book
    @return
   */
  class func logNilContentCFI(location: NYPLBookLocation?,
                              locationDictionary: Dictionary<String, Any>?,
                              bookId: String?,
                              title: String?,
                              message: String?) {
    var metadata = [AnyHashable : Any]()
    metadata["bookID"] = bookId ?? nullString
    metadata["bookTitle"] = title ?? nullString
    metadata["registry locationString"] = location?.locationString ?? nullString
    metadata["renderer"] = location?.renderer ?? nullString
    metadata["openPageRequest idref"] = locationDictionary?["idref"] ?? nullString
    addAccountInfoToMetadata(&metadata)
    
    let userInfo = additionalInfo(
      severity: .warning,
      message: message,
      metadata: metadata)
    let err = NSError(domain: Context.ereader.rawValue,
                      code: NYPLErrorCode.nilCFI.rawValue,
                      userInfo: userInfo)

    Crashlytics.sharedInstance().recordError(err)
  }
  
  /**
    Report when there's an error deauthorizing device at RMSDK level
    @return
   */
  class func logDeauthorizationError() {
    var metadata = [AnyHashable : Any]()
    addAccountInfoToMetadata(&metadata)
    
    let userInfo = additionalInfo(
      severity: .info,
      message: "User has lost an activation on signout due to NYPLAdept Error.",
      context: "NYPLSettingsAccountDetailViewController",
      metadata: metadata)
    let err = NSError(domain: Context.signOut.rawValue,
                      code: NYPLErrorCode.deAuthFail.rawValue,
                      userInfo: userInfo)

    Crashlytics.sharedInstance().recordError(err)
  }
  
  /**
    Report when there's an error logging in to an account remotely for credentials
    @param url target url being requested
    @param response HTTP response object
    @param error related error
    @param libraryName name of the library
    @return
   */
  class func logRemoteLoginError(url: NSURL?, response: URLResponse?, error: NSError?, libraryName: String?) {
    var metadata = [AnyHashable : Any]()
    metadata["libraryName"] = libraryName ?? nullString
    metadata["errorDescription"] = error?.localizedDescription ?? nullString
    metadata["errorCode"] = error?.code ?? 0
    metadata["targetUrl"] = url?.absoluteString ?? nullString
    if response != nil {
      let realResponse: URLResponse = response!
      let httpResponse = realResponse as! HTTPURLResponse
      metadata["responseStatusCode"] = httpResponse.statusCode
      metadata["responseMime"] = httpResponse.mimeType ?? nullString
    }
    addAccountInfoToMetadata(&metadata)

    let userInfo = additionalInfo(
      severity: .info,
      message: "Remote Login Failed With Error",
      metadata: metadata)
    let err = NSError(domain: Context.signIn.rawValue,
                      code: NYPLErrorCode.remoteLoginError.rawValue,
                      userInfo: userInfo)

    Crashlytics.sharedInstance().recordError(err)
  }

  /**
    Report when there's an error logging in to an account locally
    @param error related error
    @param libraryName name of the library
    @return
   */
  class func logLocalAuthFailed(error: NSError?, libraryName: String?) {
    var metadata = [AnyHashable : Any]()
    metadata["libraryName"] = libraryName ?? nullString
    metadata["errorDescription"] = error?.localizedDescription ?? nullString
    addAccountInfoToMetadata(&metadata)
    
    let userInfo = additionalInfo(
      severity: .info,
      message: "Local Login Failed With Error",
      metadata: metadata)
    let err = NSError(domain: Context.signIn.rawValue,
                      code: NYPLErrorCode.adeptAuthFail.rawValue,
                      userInfo: userInfo)

    Crashlytics.sharedInstance().recordError(err)
  }
  
  class func logDeleteBookmarkError(message: String,
                                    context: String,
                                    metadata: [String: Any]) {
    let userInfo = additionalInfo(severity: .warning,
                                  message: message,
                                  context: context,
                                  metadata: metadata)
    let err = NSError(domain: Context.ereader.rawValue,
                      code: NYPLErrorCode.deleteBookmarkFail.rawValue,
                      userInfo: userInfo)
    Crashlytics.sharedInstance().recordError(err)
  }

  /**
    Report when there's missing licensor data during deauthorization
    @param accountId id of the account
    @return
   */
  class func logInvalidLicensor(withAccountID accountId: String?) {
    var metadata = [AnyHashable : Any]()
    metadata["accountTypeID"] = accountId ?? nullString
    addAccountInfoToMetadata(&metadata)
    
    let userInfo = additionalInfo(
      severity: .warning,
      message: "No Valid Licensor available to deauthorize device. Signing out NYPLAccount credentials anyway with no message to the user.",
      context: "NYPLSettingsAccountDetailViewController",
      metadata: metadata)
    let err = NSError(domain: Context.signOut.rawValue,
                      code: NYPLErrorCode.invalidLicensor.rawValue,
                      userInfo: userInfo)

    Crashlytics.sharedInstance().recordError(err)
  }

  /**
    Report when user launches the app.
   */
  class func logNewAppLaunch() {
    var metadata = [AnyHashable : Any]()
    addAccountInfoToMetadata(&metadata)
    
    let userInfo = additionalInfo(severity: .info, metadata: metadata)
    let err = NSError(domain: NYPLSimplyEDomain,
                      code: NYPLErrorCode.appLaunch.rawValue,
                      userInfo: userInfo)

    Crashlytics.sharedInstance().recordError(err)
  }

  /**
   Report a generic path issue when dealing with file system apis.
   - parameter severity: how critical the user experience is impacted.
   - parameter message: Message to associate with report.
   - parameter context: Where this issue arose.
   */
  class func logFileSystemIssue(severity: NYPLSeverity,
                                message: String,
                                context: String) {
    let userInfo = additionalInfo(severity: severity,
                                  message: message,
                                  context: context)
    let err = NSError(domain: NYPLSimplyEDomain,
                      code: NYPLErrorCode.fileSystemFail.rawValue,
                      userInfo: userInfo)

    Crashlytics.sharedInstance().recordError(err)
  }

  /**
    Report when there's an issue with barcode image encoding
    @param exception the related exception
    @param library library for which the barcode is being created
    @return
   */
  class func logBarcodeException(_ exception: NSException?, library: String?) {
    var metadata = [AnyHashable : Any]()
    addAccountInfoToMetadata(&metadata)
    
    let userInfo = additionalInfo(
      severity: .info,
      message: "\(library ?? nullString): \(exception?.name.rawValue ?? nullString). \(exception?.reason ?? nullString)",
      context: "NYPLZXingEncoder",
      metadata: metadata)
    let err = NSError(domain: Context.signIn.rawValue,
                      code: NYPLErrorCode.barcodeException.rawValue,
                      userInfo: userInfo)

    Crashlytics.sharedInstance().recordError(err)
  }

  /**
    Report when there's an issue loading a catalog
    @param error the parsing error
    @param url the url the catalog is being fetched from
    @return
   */
  class func logCatalogLoadError(_ error: NSError, url: URL?) {
    var metadata = [AnyHashable : Any]()
    metadata["url"] = url ?? nullString
    metadata["errorDescription"] = error.localizedDescription
    addAccountInfoToMetadata(&metadata)

    let userInfo = additionalInfo(
      severity: .error,
      context: Context.catalog.rawValue,
      metadata: metadata)

    Crashlytics.sharedInstance().recordError(error,
                                             withAdditionalUserInfo: userInfo)
  }
  
  /**
   Report when there's an issue parsing a problem document.
   - parameter error: the parsing error.
   - parameter url: the url the problem document is being fetched from.
   - parameter context: client-provided operating context.
   */
  class func logProblemDocumentParseError(_ error: NSError,
                                          url: URL?,
                                          context: String) {
    var metadata = [AnyHashable : Any]()
    metadata["url"] = url ?? nullString
    metadata["errorDescription"] = error.localizedDescription
    addAccountInfoToMetadata(&metadata)
    
    let userInfo = additionalInfo(
      severity: .error,
      context: context,
      metadata: metadata)
    Crashlytics.sharedInstance().recordError(error,
                                             withAdditionalUserInfo: userInfo)
  }
  
  /**
    Report when there's an issue parsing a protocol document
    @param error the parsing error
    @return
   */
  class func logUserProfileDocumentError(error: NSError?) {
    let err = error ?? NSError(domain: Context.signIn.rawValue,
                               code: NYPLErrorCode.userProfileDocFail.rawValue,
                               userInfo: nil)
    var metadata = [AnyHashable : Any]()
    metadata["errorDescription"] = error?.localizedDescription ?? nullString
    addAccountInfoToMetadata(&metadata)

    let userInfo = additionalInfo(severity: .error, metadata: metadata)
    Crashlytics.sharedInstance().recordError(err,
                                             withAdditionalUserInfo: userInfo)
  }

  /// Reports a sign up error.
  /// - Parameters:
  ///   - error: Any error obtained during the sign up process, if present.
  ///   - code: A code identifying the error situation.
  ///   - message: A string for further context.
  class func logSignUpError(_ error: Error? = nil,
                            code: NYPLErrorCode,
                            message: String) {
    logError(error,
             code: code,
             context: Context.signUp.rawValue,
             message: message)
  }

  class func logAudiobookIssue(_ error: NSError,
                               severity: NYPLSeverity,
                               message: String? = nil) {
    let userInfo = additionalInfo(severity: severity, message: message)
    Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: userInfo)
  }

  class func logAudiobookInfoEvent(message: String) {
    let userInfo = additionalInfo(severity: .info,
                                  message: message,
                                  context: Context.audiobooks.rawValue)
    let err = NSError(domain: Context.audiobooks.rawValue,
                      code: NYPLErrorCode.audiobookUserEvent.rawValue,
                      userInfo: userInfo)
    Crashlytics.sharedInstance().recordError(err)
  }

  /// Use this function for logging low-level errors occurring in api execution
  /// when there's no other more relevant context available, or when it's more
  /// relevant to log URL and response objects.
  /// - Parameters:
  ///   - error: Any originating error obtained that occurred, if available.
  ///   - requestURL: The URL of the endpoint that returned an error response.
  ///   - response: Useful to understand if the error originated on the server.
  ///   - message: A string for further context.
  /// - Returns: The error that was logged.
  @discardableResult
  class func logNetworkError(_ error: Error? = nil,
                             requestURL: URL?,
                             response: URLResponse?,
                             message: String? = nil) -> Error {
    return logNetworkError(error,
                           requestString: requestURL?.absoluteString,
                           response: response,
                           message: message)
  }

  /// Use this function for logging low-level errors occurring in api execution
  /// when there's no other more relevant context available, or when it's more
  /// relevant to log request and response objects.
  /// - Parameters:
  ///   - error: Any originating error obtained that occurred, if available.
  ///   - request: Only the output of `loggableString` will be attached to the
  ///   report, to ensure privacy.
  ///   - response: Useful to understand if the error originated on the server.
  ///   - message: A string for further context.
  /// - Returns: The error that was logged.
  @discardableResult
  class func logNetworkError(_ error: Error? = nil,
                             request: URLRequest?,
                             response: URLResponse?,
                             message: String? = nil) -> Error {
    return logNetworkError(error,
                           requestString: request?.loggableString,
                           response: response,
                           message: message)
  }

  //----------------------------------------------------------------------------
  // MARK: - Private helpers

  @discardableResult
  private class func logNetworkError(_ error: Error? = nil,
                                     requestString: String?,
                                     response: URLResponse?,
                                     message: String? = nil) -> Error {
    // compute metadata
    var metadata = [AnyHashable : Any]()
    if let requestString = requestString {
      metadata["request"] = requestString
    }
    if let response = response {
      metadata["response"] = response
    }
    addAccountInfoToMetadata(&metadata)

    // build actual error object
    let err: Error = {
      if let error = error {
        return error
      }

      return NSError(domain: Context.infrastructure.rawValue,
                     code: NYPLErrorCode.apiCall.rawValue,
                     userInfo: nil)
    }()

    Log.error(#file, """
      Request \(requestString ?? "") failed. \
      Message: \(message ?? "<>"). Error: \(err)
      """)

    let userInfo = additionalInfo(severity: .error,
                                  message: message,
                                  metadata: metadata)
    Crashlytics.sharedInstance().recordError(err,
                                             withAdditionalUserInfo: userInfo)
    return err
  }

  /// Helper to log a generic error to Crashlytics.
  /// - Parameters:
  ///   - error: Any originating error obtained that occurred, if available.
  ///   - code: A code identifying the error situation. This is ignored if
  ///   `error` is not nil.
  ///   - context: Operating context to help identify where the error occurred.
  ///   - message: A string for further context.
  private class func logError(_ error: Error?,
                              code: NYPLErrorCode = .ignore,
                              context: String? = nil,
                              message: String? = nil) {
    var metadata = [AnyHashable : Any]()
    addAccountInfoToMetadata(&metadata)

    let err: Error = {
      if let error = error {
        return error
      }

      return NSError(domain: context ?? NYPLSimplyEDomain,
                     code: code.rawValue,
                     userInfo: nil)
    }()

    let userInfo = additionalInfo(severity: .error,
                                  message: message,
                                  context: context,
                                  metadata: metadata)

    Crashlytics.sharedInstance().recordError(err,
                                             withAdditionalUserInfo: userInfo)
  }

}
