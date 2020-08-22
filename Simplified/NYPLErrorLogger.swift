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

  // generic app related
  case appLaunch = 100
  case genericErrorMsgDisplayed = 103

  // book registry
  case unknownBookState = 203
  case registrySyncFailure = 204

  // sign in/out/up
  case invalidLicensor = 300
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

  // audiobooks
  case audiobookUserEvent = 400
  case audiobookCorrupted = 401
  case audiobookExternalError = 402

  // ereader
  case nilCFI = 500

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
  case overdriveFulfillResponseParseFail = 609

  // account management
  case authDocLoadFail = 700
  case libraryListLoadFail = 701

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
  case downloadFail = 908
  case responseFail = 909

  // DRM
  case epubDecodingError = 1000
  case adobeDRMFulfillmentFail = 1001

  // wrong content
  case unknownRightsManagement = 1100
  case unexpectedFormat = 1101

  // low-level / system related
  case missingSystemPaths = 1200
  case fileMoveFail = 1201
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

  // MARK:- Private helpers

  // TODO: SIMPLY-2992 move these private helpers to bottom of file

  /**
   Helper method for other logging functions that adds relevant library
   account info to our crash reports.
   - parameter metadata: report metadata dictionary
   */
  private class func addAccountInfoToMetadata(_ metadata: inout [String: Any]) {
    let currentLibrary = AccountsManager.shared.currentAccount
    metadata["currentAccountName"] = currentLibrary?.name ?? nullString
    metadata["currentAccountId"] = AccountsManager.shared.currentAccountId ?? nullString
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

  //----------------------------------------------------------------------------
  // MARK:- Sign up/in/out errors

  /// Report when there's an error logging in to an account.
  /// - Parameters:
  ///   - error: The error returned, if any.
  ///   - barcode: Clear-text barcode that was used to attempt sign-in. This
  ///   will be hashed.
  ///   - library: The library the user is trying to sign in into.
  ///   - request: The request issued that returned the error.
  ///   - response: The response that returned the error.
  ///   - problemDocument: A structured error description returned by the server.
  ///   - message: A dev-friendly message to concisely explain what's
  ///  happening.
  class func logLoginError(_ error: NSError?,
                           barcode: String?,
                           library: Account?,
                           request: URLRequest?,
                           response: URLResponse?,
                           problemDocument: NYPLProblemDocument?,
                           metadata: [String: Any]?) {
    var metadata = metadata ?? [String : Any]()
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
    let errorCode: Int
    if let problemDocument = problemDocument {
      metadata["problemDocument"] = problemDocument.debugDictionary
      errorCode = NYPLErrorCode.loginErrorWithProblemDoc.rawValue
    } else {
      errorCode = NYPLErrorCode.remoteLoginError.rawValue
    }
    addAccountInfoToMetadata(&metadata)

    let userInfo = additionalInfo(severity: .error, metadata: metadata)
    let err = NSError(domain: "SignIn error: problem document available",
                      code: errorCode,
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
    let err = NSError(domain: "SignIn error: Adobe activation",
                      code: NYPLErrorCode.adeptAuthFail.rawValue,
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
    let err = NSError(domain: "SignOut deauthorization error: no licensor",
                      code: NYPLErrorCode.invalidLicensor.rawValue,
                      userInfo: userInfo)

    Crashlytics.sharedInstance().recordError(err)
  }

  // MARK:- Misc

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
    Report when there's an issue with barcode image encoding
    @param exception the related exception
    @param library library for which the barcode is being created
    @return
   */
  class func logBarcodeException(_ exception: NSException?, library: String?) {
    var metadata: [String : Any] = [
      "Library": library ?? nullString,
      "ExceptionName": exception?.name ?? nullString,
      "ExceptionReason": exception?.reason ?? nullString,
    ]

    addAccountInfoToMetadata(&metadata)
    let userInfo = additionalInfo(severity: .info, metadata: metadata)

    let err = NSError(domain: "SignIn error: BarcodeScanner exception",
                      code: NYPLErrorCode.barcodeException.rawValue,
                      userInfo: userInfo)

    Crashlytics.sharedInstance().recordError(err)
  }

  class func logCatalogInitError(withCode code: NYPLErrorCode,
                                 response: URLResponse?,
                                 metadata: [String: Any]?) {
    var metadata = metadata ?? [String: Any]()
    if let response = response {
      metadata["response"] = response
    }
    logError(withCode: code,
             context: "Catalog VC Initialization",
             metadata: metadata)
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
                                          problemDocumentData: Data?,
                                          barcode: String?,
                                          url: URL?,
                                          context: String,
                                          message: String?) {
    var metadata = [String: Any]()
    addAccountInfoToMetadata(&metadata)
    metadata["url"] = url ?? nullString
    metadata["errorDescription"] = originalError.localizedDescription
    metadata[NSUnderlyingErrorKey] = originalError
    if let barcode = barcode {
      metadata["hashedBarcode"] = barcode.md5hex()
    }
    if let problemDocumentData = problemDocumentData {
      if let problemDocString = String(data: problemDocumentData, encoding: .utf8) {
        metadata["receivedProblemDocumentData"] = problemDocString
      }
    }

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
  /// TODO: SIMPLY-2992 move this together with sign-in functions
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

  //----------------------------------------------------------------------------
  // MARK:- Audiobook errors

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
    let userInfo = additionalInfo(severity: .info, message: message)
    let err = NSError(domain: "Audiobooks",
                      code: NYPLErrorCode.audiobookUserEvent.rawValue,
                      userInfo: userInfo)
    Crashlytics.sharedInstance().recordError(err)
  }

  //----------------------------------------------------------------------------
  // MARK:- Network errors

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
                             response: URLResponse? = nil,
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
      domain: context ?? "Network error",
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
  // MARK:- Private main method to report errors

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
