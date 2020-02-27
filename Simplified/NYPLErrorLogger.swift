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
}

@objcMembers class NYPLErrorLogger : NSObject {
  class func configureCrashAnalytics() {
    FirebaseApp.configure()
  }

  enum ErrorCode: Int {
    case nilCFI = 0
    case nilObject = 2
    case invalidLicensor = 3
    case deAuthFail = 4
    case bookCopyFail = 5
    case barcodeException = 8
    case appLaunch = 9
    case remoteLoginError = 10
    case nilAccount = 11
    case filePathFail = 12
    case userProfileDocFail = 14
    case audiobookEvent = 100
    case deleteBookmarkFail = 101 //previously reported as 11
    case expiredBackgroundFetch = 200
  }

  // MARK:- Generic helpers

  /**
   Helper method for other logging functions that adds logfile to our
   crash reporting system.
   - parameter metadata: report metadata dictionary
   */
  class func addLogfileToMetadata(_ metadata: inout [AnyHashable : Any]) {
    Log.logQueue.sync {
      metadata["log"] = (try? String.init(contentsOfFile: Log.logUrl.path, encoding: .utf8)) ?? ""
    }
  }
  
  /**
   Helper method for other logging functions that adds relevant account info
   to our crash reporting system.
   - parameter metadata: report metadata dictionary
   */
  class func addAccountInfoToMetadata(_ metadata: inout [AnyHashable : Any]) {
    metadata["currentAccountName"] = AccountsManager.shared.currentAccount?.name ?? nullString
    metadata["currentAccountId"] = AccountsManager.shared.currentAccountId ?? nullString
    metadata["currentAccountSet"] = AccountsManager.shared.accountSet
    metadata["numAccounts"] = AccountsManager.shared.accounts().count
  }

  /// Creates a dictionary with information to be logged in relation to an event.
  /// - Parameters:
  ///   - severity: How severe the event is.
  ///   - message: An optional message.
  ///   - context: A string identifying the page/VC where the error occurred.
  ///   - metadata: Any additional metadata.
  ///   - groupingHash: A string to group similar errors.
  private class func additionalInfo(severity: NYPLSeverity,
                                    message: String? = nil,
                                    context: String? = nil,
                                    metadata: [AnyHashable : Any]? = nil,
                                    groupingHash: String? = nil) -> [String : Any] {
    var dict: [String: Any] = ["severity": severity]
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
  class func recordUnexpectedNilIdentifier(book: NYPLBook?, identifier: String?, title: String?) {
    var metadata = [AnyHashable : Any]()
    metadata["incomingIdentifierString"] = identifier ?? nullString
    metadata["bookTitle"] = title ?? nullString
    metadata["revokeLink"] = book?.revokeURL?.absoluteString ?? nullString
    addAccountInfoToMetadata(&metadata)
    addLogfileToMetadata(&metadata)
    let userInfo = additionalInfo(
      severity: .warning,
      message: "The book identifier was unexpectedly nil when attempting to return.",
      context: "NYPLMyBooksDownloadCenter",
      metadata: metadata)
    let err = NSError(domain: simplyeDomain,
                      code: ErrorCode.nilObject.rawValue,
                      userInfo: userInfo)

    Crashlytics.sharedInstance().recordError(err)
  }
  
  /**
    Report when there's an error copying the book from RMSDK to app storage
    @param book target book
    @return
   */
  class func recordFailureToCopy(book: NYPLBook?) {
    var metadata = [AnyHashable : Any]()
    metadata["bookIdentifier"] = book?.identifier ?? nullString
    metadata["bookTitle"] = book?.title ?? nullString
    addAccountInfoToMetadata(&metadata)
    addLogfileToMetadata(&metadata)
    let userInfo = additionalInfo(
      severity: .warning,
      message: "fileURLForBookIndentifier returned nil, so no destination to copy file to.",
      context: "NYPLMyBooksDownloadCenter",
      metadata: metadata)
    let err = NSError(domain: simplyeDomain,
                      code: ErrorCode.bookCopyFail.rawValue,
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
  class func reportNilContentCFI(location: NYPLBookLocation?, locationDictionary: Dictionary<String, Any>?, bookId: String?, title: String?) {
    var metadata = [AnyHashable : Any]()
    metadata["bookID"] = bookId ?? nullString
    metadata["bookTitle"] = title ?? nullString
    metadata["registry locationString"] = location?.locationString ?? nullString
    metadata["renderer"] = location?.renderer ?? nullString
    metadata["openPageRequest idref"] = locationDictionary?["idref"] ?? nullString
    addAccountInfoToMetadata(&metadata)
    addLogfileToMetadata(&metadata)
    
    let userInfo = additionalInfo(
      severity: .warning,
      message: "No CFI parsed from NYPLBookLocation, or Readium failed to generate a CFI.",
      context: "NYPLReaderReadiumView",
      metadata: metadata,
      groupingHash: "open-book-nil-cfi")
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
    addLogfileToMetadata(&metadata)
    
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
    addLogfileToMetadata(&metadata)

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
    addLogfileToMetadata(&metadata)
    
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
    addLogfileToMetadata(&metadata)
    
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
    addLogfileToMetadata(&metadata)
    
    let userInfo = additionalInfo(
      severity: .info,
      metadata: metadata,
      groupingHash: "simplye-app-launch")
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
  class func reportFilePathIssue(severity: NYPLSeverity,
                                 message: String,
                                 context: String) {
    let userInfo = additionalInfo(severity: severity,
                                  message: message,
                                  context: context)
    let err = NSError(domain: simplyeDomain,
                      code: ErrorCode.filePathFail.rawValue,
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
    addLogfileToMetadata(&metadata)

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
    addLogfileToMetadata(&metadata)
    
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
  class func catalogLoadError(error: NSError?, url: URL?) {
    guard let err = error else {
      Log.warn(#file, "Could not log catalogLoadError because error was nil")
      return
    }
    var metadata = [AnyHashable : Any]()
    metadata["url"] = url ?? nullString
    metadata["errorDescription"] = error?.localizedDescription ?? nullString
    addAccountInfoToMetadata(&metadata)
    addLogfileToMetadata(&metadata)

    let userInfo = additionalInfo(
      severity: .error,
      metadata: metadata,
      groupingHash: "catalog-load-error")

    Crashlytics.sharedInstance().recordError(err,
                                             withAdditionalUserInfo: userInfo)
  }
  
  /**
    Report when there's an issue parsing a problem document
    @param error the parsing error
    @param url the url the problem document is being fetched from
    @return
   */
  class func logProblemDocumentParseError(error: NSError?, url: URL?) {
    guard let err = error else {
      Log.warn(#file, "Could not log a problemDocumentParserError because error was nil")
      return
    }
    var metadata = [AnyHashable : Any]()
    metadata["url"] = url ?? nullString
    metadata["errorDescription"] = error?.localizedDescription ?? nullString
    addAccountInfoToMetadata(&metadata)
    addLogfileToMetadata(&metadata)
    
    let userInfo = additionalInfo(
      severity: .error,
      metadata: metadata,
      groupingHash: "problemDocumentParseError")
    Crashlytics.sharedInstance().recordError(err,
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
    addLogfileToMetadata(&metadata)

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

  class func reportAudiobookInfoEvent(message: String, context: String) {
    let userInfo = additionalInfo(severity: .info,
                                  message: message,
                                  context: context)
    let err = NSError(domain: simplyeDomain,
                      code: ErrorCode.audiobookEvent.rawValue,
                      userInfo: userInfo)
    Crashlytics.sharedInstance().recordError(err)
  }
}
