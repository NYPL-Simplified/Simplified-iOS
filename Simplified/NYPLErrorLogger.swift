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

/// Detailed error codes that span across Contexts. E.g. you could have a
/// `invalidURLSession` for any `Context` that's using URLSession.
@objc enum NYPLErrorCode: Int {
  case ignore = 0

  // low-level / system related
  case fileSystemFail = 1

  // generic app related (101 and 102 codes are obsolete, don't use)
  case appLaunch = 100
  case genericErrorMsgDisplayed = 103

  // book registry
  case nilBookIdentifier = 200 // caused by book registry, downloads
  case nilCFI = 201
  case missingBookFile = 202
  case unknownBookState = 203
  case registrySyncFailure = 204

  // sign in/out/up (304 code is obsolete, don't use)
  case invalidLicensor = 300
  case deAuthFail = 301
  case barcodeException = 302
  case remoteLoginError = 303
  case userProfileDocFail = 305
  case nilSignUpURL = 306
  case adeptAuthFail = 307
  case noAuthorizationIdentifier = 308
  case noLicensorToken = 309
  case loginErrorWithProblemDoc = 310
  case missingParentBarcodeForJuvenile = 311
  case cardCreatorCredentialsDecodeFail = 312
  case oauthPatronInfoDecodeFail = 313
  case unrecognizedLoginUniversalLink = 314
  case validationWithoutAuthToken = 315

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
  case invalidXML = 606
  case authDocParseFail = 607
  case parseProblemDocFail = 608

  // account management
  case authDocLoadFail = 700

  // feeds
  case opdsFeedNoData = 800
  case invalidFeedType = 801
  case noAgeGateElement = 802

  // networking, generic
  case noURL = 900
  case invalidURLSession = 901 // used to be 101 up to 3.4.0
  case apiCall = 902 // used to be 102 up to 3.4.0
  case invalidResponseMimeType = 903
  case unexpectedHTTPCodeWarning = 904
  case problemDocMessageDisplayed = 905
  case unableToMakeVCAfterLoading = 906
  case noTaskInfoAvailable = 907
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
  private class func addAccountInfoToMetadata(_ metadata: inout [String: Any]) {
    let currentLibrary = AccountsManager.shared.currentAccount
    metadata["currentAccountName"] = currentLibrary?.name ?? nullString
    metadata["currentAccountId"] = AccountsManager.shared.currentAccountId ?? nullString
    metadata["currentAccountSet"] = AccountsManager.shared.accountSet
    metadata["currentAccountCatalogURL"] = currentLibrary?.catalogUrl ?? nullString
    metadata["currentAccountAuthDocURL"] = currentLibrary?.authenticationDocumentUrl ?? nullString
    metadata["currentAccountLoansURL"] = currentLibrary?.loansUrl ?? nullString
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
                                    metadata: [String: Any]? = nil) -> [String: Any] {
    var dict = metadata ?? [:]

    dict["severity"] = severity.stringValue()
    if let message = message {
      dict["message"] = message
    }
    if let context = context {
      dict["context"] = context
    }

    return dict
  }

  // MARK:- Generic methods for error logging

  /// Reports an error.
  /// - Parameters:
  ///   - error: Any originating error that occurred.
  ///   - context: Choose from `Context` enum or provide a string that can
  ///   be used to group similar errors. This will be the top line (searchable)
  ///   in Crashlytics UI.
  ///   - message: A string for further context.
  ///   - metadata: Any additional metadata to be logged.
  class func logError(_ error: Error,
                      context: String? = nil,
                      message: String? = nil,
                      metadata: [String: Any]? = nil) {
    logError(error,
             code: .ignore,
             context: context,
             message: message,
             metadata: metadata)
  }


  /// Reports an error situation.
  /// - Parameters:
  ///   - code: A code identifying the error situation. Searchable in
  ///   Crashlytics UI.
  ///   - context: Choose from `Context` enum or provide a string that can
  ///   be used to group similar errors. This will be the top line (searchable)
  ///   in Crashlytics UI.
  ///   - message: A string for further context.
  ///   - metadata: Any additional metadata to be logged.
  class func logError(withCode code: NYPLErrorCode,
                      context: String,
                      message: String? = nil,
                      metadata: [String: Any]? = nil) {
    logError(nil,
             code: code,
             context: context,
             message: message,
             metadata: metadata)
  }

  // MARK:- Specialized logging methods

  /**
    Report when there's a null book identifier
    @param book book
    @param identifier book ID
    @param title book title
    @return
   */
  class func logUnexpectedNilIdentifier(_ identifier: String?, book: NYPLBook?) {
    var metadata = [String : Any]()
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
    var metadata = [String : Any]()
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
    var metadata = [String : Any]()
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
    - Parameter error: Underlying error that happened during deauthorization.
   */
  class func logDeauthorizationError(_ error: NSError?) {
    var metadata = [String : Any]()
    addAccountInfoToMetadata(&metadata)
    if let error = error {
      metadata[NSUnderlyingErrorKey] = error
    }
    
    let userInfo = additionalInfo(
      severity: .error,
      message: "User has lost an activation on signout due to NYPLAdept Error.",
      metadata: metadata)
    let err = NSError(domain: Context.signOut.rawValue,
                      code: NYPLErrorCode.deAuthFail.rawValue,
                      userInfo: userInfo)

    Crashlytics.sharedInstance().recordError(err)
  }

  // MARK: Sign up/in/out errors

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

  /// Use this method to report an sign in error where a problem document was
  /// returned.
  /// - Parameters:
  ///   - error: The error returned, if any.
  ///   - barcode: Clear-text barcode that was used to attempt sign-in. This
  ///   will be hashed.
  ///   - library: The library the user is trying to sign in into.
  ///   - request: The request issued that returned the error.
  ///   - problemDocument: The document returned by the server.
  ///   - metadata: Any additional data to be logged.
  class func logLoginError(_ error: NSError?,
                           barcode: String?,
                           library: Account?,
                           request: URLRequest?,
                           problemDocument: NYPLProblemDocument,
                           metadata: [String: Any]?) {
    var metadata = [String : Any]()
    if let error = error {
      metadata[NSUnderlyingErrorKey] = error
    }
    if let barcode = barcode {
      metadata["hashedBarcode"] = barcode.md5hex()
    }
    if let request = request {
      metadata["request"] = request.loggableString
    }
    metadata["problemDocument"] = problemDocument.debugDictionary
    if let library = library {
      metadata["libraryUUID"] = library.uuid
      metadata["libraryName"] = library.name
    }

    addAccountInfoToMetadata(&metadata)

    let userInfo = additionalInfo(
      severity: .error,
      metadata: metadata)
    let err = NSError(domain: Context.signIn.rawValue,
                      code: NYPLErrorCode.loginErrorWithProblemDoc.rawValue,
                      userInfo: userInfo)

    Crashlytics.sharedInstance().recordError(err)
  }

  /// Report when there's an error logging in to an account remotely.
  /// - Parameters:
  ///   - error: The error returned, if any.
  ///   - barcode: Clear-text barcode that was used to attempt sign-in. This
  ///   will be hashed.
  ///   - request: The request issued that returned the error.
  ///   - response: The response that returned the error.
  ///   - library: The library the user is trying to sign in into.
  ///   - message: A dev-friendly message to concisely explain what's
  ///  happening.
  class func logRemoteLoginError(_ error: NSError?,
                                 barcode: String?,
                                 request: URLRequest?,
                                 response: URLResponse?,
                                 library: Account?,
                                 message: String) {
    var metadata = [String : Any]()
    if let error = error {
      metadata[NSUnderlyingErrorKey] = error
    }
    if let barcode = barcode {
      metadata["hashedBarcode"] = barcode.md5hex()
    }
    if let request = request {
      metadata["request"] = request.loggableString
    }
    if let response = response as? HTTPURLResponse {
      metadata["responseStatusCode"] = response.statusCode
      metadata["responseMime"] = response.mimeType ?? nullString
      metadata["responseHeaders"] = response.allHeaderFields
    }
    if let library = library {
      metadata["libraryUUID"] = library.uuid
      metadata["libraryName"] = library.name
    }
    addAccountInfoToMetadata(&metadata)

    let userInfo = additionalInfo(
      severity: .error,
      message: message,
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
  class func logLocalAuthFailed(error: NSError?,
                                library: Account?,
                                metadata: [String: Any]?) {
    var metadata = metadata ?? [String : Any]()
    if let library = library {
      metadata["libraryUUID"] = library.uuid
      metadata["libraryName"] = library.name
    }
    metadata["errorDescription"] = error?.localizedDescription ?? nullString
    if let error = error {
      metadata[NSUnderlyingErrorKey] = error
    }
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
  
  /**
   Report when there's an error deauthorizing device at RMSDK level
   */
  class func logDeauthorizationError() {
    var metadata = [String : Any]()
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
    Report when there's missing licensor data during deauthorization
    - Parameter accountId: id of the library account.
   */
  class func logInvalidLicensor(withAccountID accountId: String?) {
    var metadata = [String : Any]()
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

  // MARK: Misc

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
    Report when user launches the app.
   */
  class func logNewAppLaunch() {
    var metadata = [String : Any]()
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
    var metadata = [String : Any]()
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

  class func logCatalogInitError(withCode code: NYPLErrorCode) {
    logError(withCode: code, context: Context.catalog.rawValue)
  }

  /**
   Report when there's an issue parsing a problem document.
   - parameter originalError: the parsing error.
   - parameter barcode: The clear-text user barcode. This will be hashed.
   - parameter url: the url the problem document is being fetched from.
   - parameter context: client-provided operating context.
   - parameter message: A dev-friendly message to concisely explain what's
   happening.
   */
  class func logProblemDocumentParseError(_ originalError: NSError,
                                          barcode: String?,
                                          url: URL?,
                                          context: String,
                                          message: String?) {
    var metadata = [String: Any]()
    metadata["url"] = url ?? nullString
    metadata["errorDescription"] = originalError.localizedDescription
    metadata[NSUnderlyingErrorKey] = originalError
    if let barcode = barcode {
      metadata["hashedBarcode"] = barcode.md5hex()
    }
    addAccountInfoToMetadata(&metadata)
    
    let userInfo = additionalInfo(
      severity: .error,
      message: message,
      metadata: metadata)

    let err = NSError(domain: context,
                      code: NYPLErrorCode.parseProblemDocFail.rawValue,
                      userInfo: userInfo)

    Crashlytics.sharedInstance().recordError(err)
  }
  
  /// Report when there's an issue parsing a user profile document obtained
  /// from the server during sign in / up / out process.
  /// - Parameters:
  ///   - error: The parse error.
  ///   - context: Choose from `Context` enum or provide a string that can
  ///   be used to group similar errors. This will be the top line (searchable)
  ///   in Crashlytics UI.
  ///   - barcode: The clear-text barcode used to authenticate. This will be
  ///   hashed.
  class func logUserProfileDocumentAuthError(_ error: NSError?,
                                             context: String,
                                             barcode: String?) {
    var userInfo = [String : Any]()
    addAccountInfoToMetadata(&userInfo)
    userInfo = additionalInfo(severity: .error, metadata: userInfo)
    if let barcode = barcode {
      userInfo["hashedBarcode"] = barcode.md5hex()
    }
    if let originalError = error {
      userInfo[NSUnderlyingErrorKey] = originalError
    }

    let err = NSError(domain: context,
                      code: NYPLErrorCode.userProfileDocFail.rawValue,
                      userInfo: userInfo)

    Crashlytics.sharedInstance().recordError(err)
  }

  class func logAudiobookIssue(_ error: NSError,
                               severity: NYPLSeverity,
                               message: String? = nil) {
    var metadata = [String : Any]()
    addAccountInfoToMetadata(&metadata)

    let userInfo = additionalInfo(severity: severity,
                                  message: message,
                                  metadata: metadata)
    Crashlytics.sharedInstance().recordError(error,
                                             withAdditionalUserInfo: userInfo)
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
  /// relevant to log request and response objects.
  /// - Parameters:
  ///   - originalError: Any originating error that occurred. This will be
  ///   wrapped under `NSUnderlyingErrorKey` in Crashlytics.
  ///   - code: Client-provided code to identify errors more easily.
  ///   Searchable in Crashlytics.
  ///   - context: Client-provided context to identify errors more easily.
  ///   Searchable in Crashlytics.
  ///   - request: Only the output of `loggableString` will be attached to the
  ///   report, to ensure privacy.
  ///   - response: Useful to understand if the error originated on the server.
  ///   - message: A string for further context.
  /// - Returns: The error that was logged.
  @discardableResult
  class func logNetworkError(_ originalError: Error? = nil,
                             code: NYPLErrorCode = .ignore,
                             context: String? = nil,
                             request: URLRequest?,
                             response: URLResponse?,
                             message: String? = nil,
                             metadata: [String: Any]? = nil) -> Error {
    // compute metadata
    var metadata = metadata ?? [String : Any]()
    if let request = request {
      metadata["request"] = request.loggableString
    }
    if let response = response {
      metadata["response"] = response
    }
    if let originalError = originalError {
      metadata[NSUnderlyingErrorKey] = originalError
    }
    addAccountInfoToMetadata(&metadata)

    let userInfo = additionalInfo(severity: .error,
                                  message: message,
                                  metadata: metadata)
    let error = NSError(
      domain: context ?? Context.infrastructure.rawValue,
      code: (code != .ignore ? code : NYPLErrorCode.apiCall).rawValue,
      userInfo: userInfo)

    Log.error(#file, """
      Request \(request?.loggableString ?? "") failed. \
      Message: \(message ?? "<>"). Error: \(originalError ?? error)
      """)

    Crashlytics.sharedInstance().recordError(error)
    return error
  }

  //----------------------------------------------------------------------------
  // MARK: - Private helpers

  /// Helper to log a generic error to Crashlytics.
  /// - Parameters:
  ///   - originalError: Any originating error that occurred, if available.
  ///   - code: A code identifying the error situation. This is ignored if
  ///   `error` is not nil.
  ///   - context: Operating context to help identify where the error occurred.
  ///   - message: A string for further context.
  ///   - metadata: Any additional metadata to be logged.
  private class func logError(_ originalError: Error?,
                              code: NYPLErrorCode = .ignore,
                              context: String? = nil,
                              message: String? = nil,
                              metadata: [String: Any]? = nil) {
    if let message = message {
      Log.error(#file, message)
    }

    var moreMetadata = metadata ?? [String : Any]()
    addAccountInfoToMetadata(&moreMetadata)

    if let originalError = originalError {
      Log.error(#file, "Error: \(originalError)")
      moreMetadata[NSUnderlyingErrorKey] = originalError
    }

    let userInfo = additionalInfo(severity: .error,
                                  message: message,
                                  metadata: moreMetadata)

    let finalCode: Int
    if code != .ignore {
      finalCode = code.rawValue
    } else if let nserror = originalError as NSError? {
      finalCode = nserror.code
    } else {
      finalCode = NYPLErrorCode.ignore.rawValue
    }

    let err = NSError(domain: context ?? NYPLSimplyEDomain,
                      code: finalCode,
                      userInfo: userInfo)

    Crashlytics.sharedInstance().recordError(err)
  }

}
