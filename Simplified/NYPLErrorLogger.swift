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

@objcMembers class NYPLErrorLogger : NSObject {
  class func configureCrashAnalytics() {
    FirebaseApp.configure()
  }

  /// Broad areas providing some kind of operating context for error reporting.
  /// These are meant to be related to the code base more than functionality,
  /// (e.g. an error related to audiobooks may happen in different classes)
  /// although the two things may obviously overlap.
  enum Context: String {
    case bookDownload
    case audiobooks
    case myBooks
    case readium
  }

  enum ErrorCode: Int {
    // low-level / system related
    case fileSystemFail = 1

    // generic app related
    case appLaunch = 100
    case expiredBackgroundFetch = 101

    // book registry
    case nilBookIdentifier = 200 // caused by book registry, downloads
    case nilCFI = 201
    case missingBookFile = 202

    // sign in/out
    case invalidLicensor = 300
    case deAuthFail = 301
    case barcodeException = 302
    case remoteLoginError = 303
    case nilAccount = 304
    case userProfileDocFail = 305

    // audiobooks
    case audiobookEvent = 400

    // ereader
    case deleteBookmarkFail = 500
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
  ///   - groupingHash: A string to group similar errors.
  private class func additionalInfo(severity: NYPLSeverity,
                                    message: String? = nil,
                                    context: String? = nil,
                                    metadata: [AnyHashable : Any]? = nil,
                                    groupingHash: String? = nil) -> [String : Any] {
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
    if let groupingHash = groupingHash {
      dict["groupingHash"] = groupingHash
    }
    return dict
  }

  // MARK:- Error reporting

  /**
    Report when there's a null book identifier
    @param book book
    @param identifier book ID
    @param title book title
    @return
   */
  class func recordUnexpectedNilIdentifier(_ identifier: String?, book: NYPLBook?) {
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
                      code: ErrorCode.nilBookIdentifier.rawValue,
                      userInfo: userInfo)

    Crashlytics.sharedInstance().recordError(err)
  }
  
  /**
    Report when there's an error copying the book from RMSDK to app storage
    @param book target book
    @return
   */
  class func recordMissingFileURLAfterDownloadingBook(_ book: NYPLBook?,
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
                      code: ErrorCode.missingBookFile.rawValue,
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
  class func reportNilContentCFI(location: NYPLBookLocation?,
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
    let err = NSError(domain: simplyeDomain, code: ErrorCode.nilCFI.rawValue, userInfo: userInfo)

    Crashlytics.sharedInstance().recordError(err)
  }
  
  /**
    Report when there's an error deauthorizing device at RMSDK level
    @return
   */
  class func deauthorizationError() {
    var metadata = [AnyHashable : Any]()
    addAccountInfoToMetadata(&metadata)
    reportLogs()
    
    let userInfo = additionalInfo(
      severity: .info,
      message: "User has lost an activation on signout due to NYPLAdept Error.",
      context: "NYPLSettingsAccountDetailViewController",
      metadata: metadata)
    let err = NSError(domain: simplyeDomain,
                      code: ErrorCode.deAuthFail.rawValue,
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
  class func reportRemoteLoginError(url: NSURL?, response: URLResponse?, error: NSError?, libraryName: String?) {
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
                      code: ErrorCode.remoteLoginError.rawValue,
                      userInfo: userInfo)

    Crashlytics.sharedInstance().recordError(err)
  }

  class func reportUnexpectedNilAccount(context: String) {
    let userInfo = additionalInfo(severity: .error, context: context)
    let err = NSError(domain: simplyeDomain,
                      code: ErrorCode.nilAccount.rawValue,
                      userInfo: userInfo)

    Crashlytics.sharedInstance().recordError(err)
  }

  /**
    Report when there's an error logging in to an account locally
    @param error related error
    @param libraryName name of the library
    @return
   */
  class func reportLocalAuthFailed(error: NSError?, libraryName: String?) {
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
  
  class func reportDeleteBookmarkError(message: String,
                                       context: String,
                                       metadata: [String: Any]) {
    let userInfo = additionalInfo(severity: .warning,
                                  message: message,
                                  context: context,
                                  metadata: metadata)
    let err = NSError(domain: simplyeDomain,
                      code: ErrorCode.deleteBookmarkFail.rawValue,
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
                      code: ErrorCode.invalidLicensor.rawValue,
                      userInfo: userInfo)

    Crashlytics.sharedInstance().recordError(err)
  }

  /**
    Report when user launches the app.
   */
  class func reportNewAppLaunch() {
    var metadata = [AnyHashable : Any]()
    addAccountInfoToMetadata(&metadata)
    reportLogs()
    
    let userInfo = additionalInfo(severity: .info, metadata: metadata)
    let err = NSError(domain: simplyeDomain,
                      code: ErrorCode.appLaunch.rawValue,
                      userInfo: userInfo)

    Crashlytics.sharedInstance().recordError(err)
  }

  /**
   Report a generic path issue when dealing with file system apis.
   - parameter severity: how critical the user experience is impacted.
   - parameter message: Message to associate with report.
   - parameter context: Where this issue arose.
   */
  class func reportFileSystemIssue(severity: NYPLSeverity,
                                   message: String,
                                   context: String) {
    let userInfo = additionalInfo(severity: severity,
                                  message: message,
                                  context: context)
    let err = NSError(domain: simplyeDomain,
                      code: ErrorCode.fileSystemFail.rawValue,
                      userInfo: userInfo)

    Crashlytics.sharedInstance().recordError(err)
  }

  /**
    Report when there's an issue downloading the holds in the background
    @return
   */
  class func reportExpiredBackgroundFetch() {
    var metadata = [AnyHashable : Any]()
    metadata["loanUrl"] = AccountsManager.shared.currentAccount?.loansUrl ?? nullString
    addAccountInfoToMetadata(&metadata)
    reportLogs()

    let userInfo = additionalInfo(
      severity: .error,
      metadata: metadata,
      groupingHash: "BackgroundFetchExpired")
    let err = NSError(domain: simplyeDomain,
                      code: ErrorCode.expiredBackgroundFetch.rawValue,
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
                      code: ErrorCode.barcodeException.rawValue,
                      userInfo: userInfo)

    Crashlytics.sharedInstance().recordError(err)
  }

  /**
    Report when there's an issue loading a catalog
    @param error the parsing error
    @param url the url the catalog is being fetched from
    @return
   */
  class func reportCatalogLoadError(_ error: NSError, url: URL?) {
    var metadata = [AnyHashable : Any]()
    metadata["url"] = url ?? nullString
    metadata["errorDescription"] = error.localizedDescription
    addAccountInfoToMetadata(&metadata)
    reportLogs()

    let userInfo = additionalInfo(
      severity: .error,
      metadata: metadata,
      groupingHash: "catalog-load-error")

    Crashlytics.sharedInstance().recordError(error,
                                             withAdditionalUserInfo: userInfo)
  }
  
  /**
    Report when there's an issue parsing a problem document
    @param error the parsing error
    @param url the url the problem document is being fetched from
    @return
   */
  class func logProblemDocumentParseError(_ error: NSError, url: URL?) {
    var metadata = [AnyHashable : Any]()
    metadata["url"] = url ?? nullString
    metadata["errorDescription"] = error.localizedDescription
    addAccountInfoToMetadata(&metadata)
    reportLogs()
    
    let userInfo = additionalInfo(
      severity: .error,
      metadata: metadata,
      groupingHash: "problemDocumentParseError")
    Crashlytics.sharedInstance().recordError(error,
                                             withAdditionalUserInfo: userInfo)
  }
  
  /**
    Report when there's an issue parsing a protocol document
    @param error the parsing error
    @return
   */
  class func reportUserProfileDocumentError(error: NSError?) {
    let err = error ?? NSError.init(domain: simplyeDomain,
                                    code: ErrorCode.userProfileDocFail.rawValue,
                                    userInfo: nil)
    var metadata = [AnyHashable : Any]()
    metadata["errorDescription"] = error?.localizedDescription ?? nullString
    addAccountInfoToMetadata(&metadata)
    reportLogs()

    let userInfo = additionalInfo(severity: .error, metadata: metadata)
    Crashlytics.sharedInstance().recordError(err,
                                             withAdditionalUserInfo: userInfo)
  }

  class func reportAudiobookIssue(_ error: NSError,
                                  severity: NYPLSeverity,
                                  message: String? = nil) {
    let userInfo = additionalInfo(severity: severity, message: message)
    Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: userInfo)
  }

  class func reportAudiobookInfoEvent(message: String) {
    let userInfo = additionalInfo(severity: .info,
                                  message: message,
                                  context: Context.audiobooks.rawValue)
    let err = NSError(domain: simplyeDomain,
                      code: ErrorCode.audiobookEvent.rawValue,
                      userInfo: userInfo)
    Crashlytics.sharedInstance().recordError(err)
  }
}
