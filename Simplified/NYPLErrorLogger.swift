//
//  SimplyE
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation
import Firebase

fileprivate let simplyeDomain = "org.nypl.labs.SimplyE"
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
  case noErr = 0

  // low-level / system related
  case fileSystemFail = 1

  // generic app related
  case appLaunch = 100
  case expiredBackgroundFetch = 101
  case apiCall = 102

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
  case nilAccount = 304
  case userProfileDocFail = 305
  case nilSignUpURL = 306

  // audiobooks
  case audiobookEvent = 400

  // ereader
  case deleteBookmarkFail = 500

  // Parse failure
  case parseProfileDataCorrupted = 600
  case parseProfileTypeMismatch = 601
  case parseProfileValueNotFound = 602
  case parseProfileKeyNotFound = 603
}

@objcMembers class NYPLErrorLogger : NSObject {
  class func configureCrashAnalytics() {
    FirebaseApp.configure()
  }

  /// Broad areas providing some kind of operating context for error reporting.
  /// These are meant to be related to the code base more than functionality,
  /// (e.g. an error related to audiobooks may happen in different classes)
  /// although the two things may obviously overlap.
  enum Context: String {
    case catalog
    case bookDownload
    case audiobooks
    case myBooks
    case readium
    case signUp
  }

  // MARK:- Generic helpers

  /**
   Helper method for other logging functions that adds logs to our
   crash reporting system.
   */
  private class func reportLogs() {
    Log.logQueue.sync {
      if let logs = (try? String(contentsOfFile: Log.logUrl.path, encoding: .utf8)) {
        CLSNSLogv("%@",  getVaList([logs]))
      }
    }
  }
  
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

  /// Reports a generic error situation.
  /// - Parameters:
  ///   - error: Any originating error obtained that occurred, if available.
  ///   - code: A code identifying the error situation.
  ///   - message: A string for further context.
  class func logError(_ error: Error? = nil,
                      code: NYPLErrorCode = .noErr,
                      message: String) {
    logError(error, code: code, message: message)
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
    reportLogs()
    let userInfo = additionalInfo(
      severity: .warning,
      message: "The book identifier was unexpectedly nil when attempting to return.",
      context: Context.myBooks.rawValue,
      metadata: metadata)
    let err = NSError(domain: simplyeDomain,
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
    reportLogs()
    let userInfo = additionalInfo(
      severity: .warning,
      message: message,
      context: Context.bookDownload.rawValue,
      metadata: metadata)
    let err = NSError(domain: simplyeDomain,
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
    reportLogs()
    
    let userInfo = additionalInfo(
      severity: .warning,
      message: message,
      context: Context.readium.rawValue,
      metadata: metadata)
    let err = NSError(domain: simplyeDomain,
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
    reportLogs()
    
    let userInfo = additionalInfo(
      severity: .info,
      message: "User has lost an activation on signout due to NYPLAdept Error.",
      context: "NYPLSettingsAccountDetailViewController",
      metadata: metadata)
    let err = NSError(domain: simplyeDomain,
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
    reportLogs()

    let userInfo = additionalInfo(
      severity: .info,
      message: "Remote Login Failed With Error",
      metadata: metadata)
    let err = NSError(domain: simplyeDomain,
                      code: NYPLErrorCode.remoteLoginError.rawValue,
                      userInfo: userInfo)

    Crashlytics.sharedInstance().recordError(err)
  }

  class func logUnexpectedNilAccount(context: String) {
    let userInfo = additionalInfo(severity: .error, context: context)
    let err = NSError(domain: simplyeDomain,
                      code: NYPLErrorCode.nilAccount.rawValue,
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
    reportLogs()
    
    let userInfo = additionalInfo(
      severity: .info,
      message: "Local Login Failed With Error",
      metadata: metadata)
    let err = NSError(domain: simplyeDomain, code: 11, userInfo: userInfo)

    Crashlytics.sharedInstance().recordError(err)
  }
  
  class func logDeleteBookmarkError(message: String,
                                    context: String,
                                    metadata: [String: Any]) {
    let userInfo = additionalInfo(severity: .warning,
                                  message: message,
                                  context: context,
                                  metadata: metadata)
    let err = NSError(domain: simplyeDomain,
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
    reportLogs()
    
    let userInfo = additionalInfo(
      severity: .warning,
      message: "No Valid Licensor available to deauthorize device. Signing out NYPLAccount credentials anyway with no message to the user.",
      context: "NYPLSettingsAccountDetailViewController",
      metadata: metadata)
    let err = NSError(domain: simplyeDomain,
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
    reportLogs()
    
    let userInfo = additionalInfo(severity: .info, metadata: metadata)
    let err = NSError(domain: simplyeDomain,
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
    let err = NSError(domain: simplyeDomain,
                      code: NYPLErrorCode.fileSystemFail.rawValue,
                      userInfo: userInfo)

    Crashlytics.sharedInstance().recordError(err)
  }

  /**
    Report when there's an issue downloading the holds in the background
    @return
   */
  class func logExpiredBackgroundFetch() {
    var metadata = [AnyHashable : Any]()
    metadata["loanUrl"] = AccountsManager.shared.currentAccount?.loansUrl ?? nullString
    addAccountInfoToMetadata(&metadata)
    reportLogs()

    let userInfo = additionalInfo(severity: .error, metadata: metadata)
    let err = NSError(domain: simplyeDomain,
                      code: NYPLErrorCode.expiredBackgroundFetch.rawValue,
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
    reportLogs()
    
    let userInfo = additionalInfo(
      severity: .info,
      message: "\(library ?? nullString): \(exception?.name.rawValue ?? nullString). \(exception?.reason ?? nullString)",
      context: "NYPLZXingEncoder",
      metadata: metadata)
    let err = NSError(domain: simplyeDomain,
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
    reportLogs()

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
    reportLogs()
    
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
    let err = error ?? NSError(domain: simplyeDomain,
                               code: NYPLErrorCode.userProfileDocFail.rawValue,
                               userInfo: nil)
    var metadata = [AnyHashable : Any]()
    metadata["errorDescription"] = error?.localizedDescription ?? nullString
    addAccountInfoToMetadata(&metadata)
    reportLogs()

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
                            code: NYPLErrorCode = .noErr,
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
    let err = NSError(domain: simplyeDomain,
                      code: NYPLErrorCode.audiobookEvent.rawValue,
                      userInfo: userInfo)
    Crashlytics.sharedInstance().recordError(err)
  }

  @discardableResult
  class func logNetworkError(_ error: Error? = nil,
                             requestURL: URL? = nil,
                             response: URLResponse? = nil,
                             message: String? = nil) -> Error {
    // compute metadata
    var metadata = [AnyHashable : Any]()
    if let requestURL = requestURL {
      metadata["requestURL"] = requestURL
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

      return NSError(domain: simplyeDomain,
                     code: NYPLErrorCode.apiCall.rawValue,
                     userInfo: nil)
    }()

    Log.error(#file, """
      Request with URL \(String(describing: requestURL)) failed. \
      Message: \(message ?? "<>"). Error: \(err)
      """)
    reportLogs()

    let userInfo = additionalInfo(severity: .error,
                                  message: message,
                                  metadata: metadata)
    Crashlytics.sharedInstance().recordError(err,
                                             withAdditionalUserInfo: userInfo)
    return err
  }

  //----------------------------------------------------------------------------
  // MARK: -

  /// Reports a sign up error.
  /// - Parameters:
  ///   - error: Any error obtained during the sign up process, if present.
  ///   - code: A code identifying the error situation.
  ///   - context: Operating context to help identify where the error occurred.
  ///   - message: A string for further context.
  private class func logError(_ error: Error? = nil,
                              code: NYPLErrorCode = .noErr,
                              context: String? = nil,
                              message: String) {
    var metadata = [AnyHashable : Any]()
    addAccountInfoToMetadata(&metadata)

    let err: Error = {
      if let error = error {
        return error
      }

      return NSError(domain: simplyeDomain, code: code.rawValue, userInfo: nil)
    }()

    let userInfo = additionalInfo(severity: .error,
                                  message: message,
                                  context: context,
                                  metadata: metadata)
    reportLogs()
    Crashlytics.sharedInstance().recordError(err,
                                             withAdditionalUserInfo: userInfo)
  }

}
