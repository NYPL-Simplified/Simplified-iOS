//
//  SimplyE
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation
import Bugsnag

fileprivate let simplyeDomain = "org.nypl.labs.SimplyE"
fileprivate let nullString = "null"
fileprivate let tabName = "Extra Data"

@objc enum NYPLSeverity: NSInteger {
  case error, warning, info
}

@objcMembers class NYPLErrorLogger : NSObject {
  class func configureCrashAnalytics() {
    let config = BugsnagConfiguration()
    config.apiKey = APIKeys.bugsnagID

    #if DEBUG
    config.releaseStage = "development"
    #else
    if releaseStageIsBeta() {
      config.releaseStage = "beta"
      if let userID = NYPLAccount.shared()?.barcode {
        config.setUser(userID, withName: nil, andEmail: nil)
      }
    } else {
      config.releaseStage = "production"
    }
    #endif

    Bugsnag.start(with: config)
  }

  private class func releaseStageIsBeta() -> Bool {
    guard let receiptURLPath = Bundle.main.appStoreReceiptURL?.path else {
      // returning true here is somewhat odd, but it was left for backward
      // compatibility reasons with previous objc code
      return true
    }

    return receiptURLPath.contains("sandboxReceipt")
  }

  /**
    Helper method for other logging functions that adds logfile to bugsnag report
    @param metadata report metadata dictionary
    @return
   */
  class func addLogfileToMetadata(_ metadata: inout [AnyHashable : Any]) {
    Log.logQueue.sync {
      metadata["log"] = (try? String.init(contentsOfFile: Log.logUrl.path, encoding: .utf8)) ?? ""
    }
  }
  
  /**
    Helper method for other logging functions that adds relevant account info to bugsnag report
    @param metadata report metadata dictionary
    @return
   */
  class func addAccountInfoToMetadata(_ metadata: inout [AnyHashable : Any]) {
    metadata["currentAccountName"] = AccountsManager.shared.currentAccount?.name ?? nullString
    metadata["currentAccountId"] = AccountsManager.shared.currentAccountId ?? nullString
    metadata["currentAccountSet"] = AccountsManager.shared.accountSet
    metadata["numAccounts"] = AccountsManager.shared.accounts().count
  }
  
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
    
    Bugsnag.notifyError(NSError.init(domain: simplyeDomain, code: 2, userInfo: nil), block: { report in
      report.context = "NYPLMyBooksDownloadCenter"
      report.severity = .warning
      report.errorMessage = "The book identifier was unexpectedly nil when attempting to return."
      report.addMetadata(metadata, toTabWithName: tabName)
    })
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
    
    Bugsnag.notifyError(NSError.init(domain: simplyeDomain, code: 5, userInfo: nil), block: { report in
      report.context = "NYPLMyBooksDownloadCenter"
      report.severity = .warning
      report.errorMessage = "fileURLForBookIndentifier returned nil, so no destination to copy file to."
      report.addMetadata(metadata, toTabWithName: tabName)
    })
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
    
    Bugsnag.notifyError(NSError.init(domain: simplyeDomain, code: 0, userInfo: nil), block: { report in
      report.context = "NYPLReaderReadiumView"
      report.severity = .warning
      report.groupingHash = "open-book-nil-cfi"
      report.errorMessage = "No CFI parsed from NYPLBookLocation, or Readium failed to generate a CFI."
      report.addMetadata(metadata, toTabWithName: tabName)
    })
  }
  
  /**
    Report when there's an error deauthorizing device at RMSDK level
    @return
   */
  class func deauthorizationError() {
    var metadata = [AnyHashable : Any]()
    addAccountInfoToMetadata(&metadata)
    addLogfileToMetadata(&metadata)
    
    Bugsnag.notifyError(NSError.init(domain: simplyeDomain, code: 4, userInfo: nil), block: { report in
      report.context = "NYPLSettingsAccountDetailViewController"
      report.severity = .info
      report.errorMessage = "User has lost an activation on signout due to NYPLAdept Error."
      report.addMetadata(metadata, toTabWithName: tabName)
    })
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
    
    Bugsnag.notifyError(NSError.init(domain: simplyeDomain, code: 10, userInfo: nil), block: { report in
      report.severity = .info
      report.errorMessage = "Remote Login Failed With Error"
      report.addMetadata(metadata, toTabWithName: tabName)
    })
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
    
    Bugsnag.notifyError(NSError.init(domain: simplyeDomain, code: 11, userInfo: nil), block: { report in
      report.severity = .info
      report.errorMessage = "Local Login Failed With Error"
      report.addMetadata(metadata, toTabWithName: tabName)
    })
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
    
    Bugsnag.notifyError(NSError.init(domain: simplyeDomain, code: 3, userInfo: nil), block: { report in
      report.context = "NYPLSettingsAccountDetailViewController"
      report.severity = .warning
      report.errorMessage = "No Valid Licensor available to deauthorize device. Signing out NYPLAccount credentials anyway with no message to the user."
      report.addMetadata(metadata, toTabWithName: tabName)
    })
  }

  /**
    Report new app session
    @return
   */
  class func reportNewActiveSession() {
    var metadata = [AnyHashable : Any]()
    addAccountInfoToMetadata(&metadata)
    addLogfileToMetadata(&metadata)
    
    Bugsnag.notifyError(NSError.init(domain: simplyeDomain, code: 9, userInfo: nil), block: { report in
      report.severity = .info
      report.groupingHash = "simplye-app-launch"
      report.addMetadata(metadata, toTabWithName: tabName)
    })
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
    
    let exception = NSException.init(name: NSExceptionName.init(
      rawValue: "BackgroundFetchExpired"),reason: nil, userInfo: nil)
    
    Bugsnag.notify(exception, block: { report in
      report.severity = .warning
      report.groupingHash = "BackgroundFetchExpired"
      report.addMetadata(metadata, toTabWithName: tabName)
    })
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
    
    Bugsnag.notifyError(NSError.init(domain: simplyeDomain, code: 8, userInfo: nil), block: { report in
      report.context = "NYPLZXingEncoder"
      report.severity = .info
      report.errorMessage = "\(library ?? nullString): \(exception?.name.rawValue ?? nullString). \(exception?.reason ?? nullString)"
      report.addMetadata(metadata, toTabWithName: tabName)
    })
  }


  /// Logs a generic exception.
  /// - Parameter exception: The exception to be logged.
  class func logException(_ exception: NSException) {
    Bugsnag.notify(exception)
  }
  
  /**
    Report when there's an issue loading a catalog
    @param error the parsing error
    @param url the url the catalog is being fetched from
    @return
   */
  class func catalogLoadError(error: NSError?, url: URL?) {
    guard let err = error else {
      Log.warn(#file, "Could not log bugsnag catalogLoadError because error was nil")
      return
    }
    var metadata = [AnyHashable : Any]()
    metadata["url"] = url ?? nullString
    metadata["errorDescription"] = error?.localizedDescription ?? nullString
    addAccountInfoToMetadata(&metadata)
    addLogfileToMetadata(&metadata)
    
    Bugsnag.notifyError(err, block: { report in
      report.groupingHash = "catalog-load-error"
      report.addMetadata(metadata, toTabWithName: tabName)
    })
  }
  
  /**
    Report when there's an issue parsing a problem document
    @param error the parsing error
    @param url the url the problem document is being fetched from
    @return
   */
  class func logProblemDocumentParseError(error: NSError?, url: URL?) {
    guard let err = error else {
      Log.warn(#file, "Could not log bugsnag catalogLoadError because error was nil")
      return
    }
    var metadata = [AnyHashable : Any]()
    metadata["url"] = url ?? nullString
    metadata["errorDescription"] = error?.localizedDescription ?? nullString
    addAccountInfoToMetadata(&metadata)
    addLogfileToMetadata(&metadata)
    
    Bugsnag.notifyError(err, block: { report in
      report.groupingHash = "problemDocumentParseError"
      report.addMetadata(metadata, toTabWithName: tabName)
    })
  }
  
  /**
    Report when there's an issue parsing a protocol document
    @param error the parsing error
    @return
   */
  class func reportUserProfileDocumentError(error: NSError?) {
    let err = error ?? NSError.init(domain: "org.nypl.labs.SimplyE", code: 14, userInfo: nil)
    var metadata = [AnyHashable : Any]()
    metadata["errorDescription"] = error?.localizedDescription ?? nullString
    addAccountInfoToMetadata(&metadata)
    addLogfileToMetadata(&metadata)
    
    Bugsnag.notifyError(err, block: { report in
      report.addMetadata(metadata, toTabWithName: tabName)
    })
  }


  /// Report a generic error with a given message.
  /// - Parameters:
  ///   - error: The error that occurred.
  ///   - message: The message to append for more context.
  /// - Note: Only use from Objc. From Swift, use
  /// report(:with:severity:groupingHash:context:metadata:).
  @objc(reportError:message:)
  class func objc_reportError(_ error: Error, message: String) {
    report(error, with: message)
  }


  /// Logs a generic error with associated information.
  /// - Parameters:
  ///   - error: The error that occurred.
  ///   - message: An optional message.
  ///   - severity: How severe the error is.
  ///   - groupingHash: A string to group similar errors.
  ///   - context: A string identifying the page/VC where the error occurred.
  ///   - metadata: Any additional metadata.
  @objc(reportError:message:severity:groupingHash:context:metadata:)
  class func report(_ error: Error,
                    with message: String? = nil,
                    severity: NYPLSeverity = .error,
                    groupingHash: String? = nil,
                    context: String? = nil,
                    metadata: [AnyHashable : Any]? = nil) {
    Bugsnag.notifyError(error) { report in
      report.errorMessage = message
      switch severity {
      case .error:
        report.severity = .error
      case .warning:
        report.severity = .warning
      case .info:
        report.severity = .info
      }
      report.groupingHash = groupingHash
      report.context = context
      if let metadata = metadata {
        report.addMetadata(metadata, toTabWithName: tabName)
      }
    }
  }
}
