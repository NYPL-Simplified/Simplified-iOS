import Foundation
import Bugsnag

fileprivate let simplyeDomain = "org.nypl.labs.SimplyE"
fileprivate let nullString = "null"
fileprivate let tabName = "Extra Data"

@objcMembers class NYPLBugsnagLogs : NSObject {
  
  class func addLogfileToMetadata(_ metadata: inout [AnyHashable : Any]) {
    Log.logQueue.sync {
      metadata["log"] = (try? String.init(contentsOfFile: Log.logUrl.path, encoding: .utf8)) ?? ""
    }
  }
  
  class func addAccountInfoToMetadata(_ metadata: inout [AnyHashable : Any]) {
    metadata["currentAccount"] = AccountsManager.shared.currentAccount ?? nullString
    metadata["currentAccountId"] = AccountsManager.shared.currentAccountId ?? nullString
    metadata["numAccounts"] = AccountsManager.shared.accounts.count
  }
  
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
  
  class func reportNilContentCFIToBugsnag(location: NYPLBookLocation?, locationDictionary: Dictionary<String, Any>?, bookId: String?, title: String?) {
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
  
  class func loginAlertError(error: NSError?, code: Int, libraryName: String?) {
    //FIXME: Remove Bugsnag log when DRM Activation moves to the auth document
    if error?.domain == NSURLErrorDomain {
      var metadata = [AnyHashable : Any]()
      metadata["libraryName"] = libraryName ?? nullString
      metadata["errorCode"] = code
      addAccountInfoToMetadata(&metadata)
      addLogfileToMetadata(&metadata)
      
      Bugsnag.notifyError(NSError.init(domain: simplyeDomain, code: 10, userInfo: nil), block: { report in
        report.severity = .info
        report.errorMessage = "Login Failed With Error"
        report.addMetadata(metadata, toTabWithName: tabName)
      })
    }
  }
  
  class func bugsnagLogInvalidLicensorWith(accountId: String?) {
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
  
  class func reportExpiredBackgroundFetch() {
    var metadata = [AnyHashable : Any]()
    metadata["loanUrl"] = NYPLConfiguration.loanURL() ?? nullString
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
  
  class func logExceptionToBugsnag(exception: NSException?, library: String?) {
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
  
  class func catalogLoadError(error: NSError?, url: URL?) {
    guard let err = error else {
      Log.warn(#file, "Could not log bugsnag catalogLoadError because error was nil")
      return
    }
    var metadata = [AnyHashable : Any]()
    metadata["url"] = url ?? nullString
    addAccountInfoToMetadata(&metadata)
    addLogfileToMetadata(&metadata)
    
    Bugsnag.notifyError(err, block: { report in
      report.groupingHash = "catalog-load-error"
      report.addMetadata(metadata, toTabWithName: tabName)
    })
  }
}
