/// For any special-case information that's sent as a report to Bugsnag.
/// Groom this occassionally: if the information being collected is not useful,
/// then get rid of it.
@objcMembers final class NYPLBugsnagReports: NSObject {

  /// May be interesting to know if very long syncs are occurring during background fetch..
  class func expiredBackgroundFetch() {
    let currentLibrary = AccountsManager.shared.currentAccount.id
    let exceptionName = "BackgroundFetchExpired-Library-\(currentLibrary)"
    let exception = NSException(name: NSExceptionName(rawValue: exceptionName), reason: nil, userInfo: nil)
    Bugsnag.notify(exception) { report in
      report.groupingHash = exceptionName
      report.severity = .warning
      report.addMetadata(["Library" : currentLibrary], toTabWithName: "Extra Info")
    }
  }
}
