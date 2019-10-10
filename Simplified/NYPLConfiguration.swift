import Bugsnag


@objcMembers class NYPLConfiguration : NSObject {
  // Static stuff
  class func initConfig () {
    self.configureCrashAnalytics()
  }
  
  private class func configureCrashAnalytics() {
    #if !targetEnvironment(simulator)
      let bugsnagConfig = BugsnagConfiguration()
      bugsnagConfig.apiKey = APIKeys.bugsnagID

      #if DEBUG
        bugsnagConfig.releaseStage = "development"
      #else
        if (self.releaseStageIsBeta()) {
          bugsnagConfig.releaseStage = "beta"
          if (NYPLAccount.shared()?.barcode != nil) {
            bugsnagConfig.setUser(NYPLAccount.shared()?.barcode, withName: nil, andEmail: nil)
          }
        } else {
          bugsnagConfig.releaseStage = "production"
        }
      #endif

      Bugsnag.start(with: bugsnagConfig)
      NYPLBugsnagLogs.reportNewActiveSession()
    #endif
  }
  
  private class func releaseStageIsBeta() -> Bool {
    let receiptURL = Bundle.main.appStoreReceiptURL
    return (TARGET_OS_SIMULATOR == 0) || (receiptURL?.path.contains("sandboxReceipt") ?? false)
  }
  
  fileprivate static let _betaUrl = URL(string: "https://libraryregistry.librarysimplified.org/libraries/qa")!
  fileprivate static let _prodUrl = URL(string: "https://libraryregistry.librarysimplified.org/libraries")!
  fileprivate static let _betaUrlHash = _betaUrl.absoluteString.md5().base64EncodedStringUrlSafe().trimmingCharacters(in: ["="])
  fileprivate static let _prodUrlHash = _prodUrl.absoluteString.md5().base64EncodedStringUrlSafe().trimmingCharacters(in: ["="])

  static var shared = NYPLConfiguration()

  // Member vars
  var mainFeedURL: URL? {
    return NYPLSettings.shared.customMainFeedURL ?? NYPLSettings.shared.accountMainFeedURL
  }

  let cardCreationEnabled = true

  let minimumVersionURL = URL.init(string: "http://www.librarysimplified.org/simplye-client/minimum-version")
  
  var mainColor: UIColor {
    let mc = AccountsManager.shared.currentAccount?.details?.mainColor
    return mc != nil ? NYPLAppTheme.themeColorFromString(name: mc!) : UIColor.black
  }
  
  let accentColor = UIColor.init(red: 0.0, green: 144/255.0, blue: 196/255.0, alpha: 1.0)
  
  let backgroundColor = UIColor.init(white: 250/255.0, alpha: 1.0)
  
  let backgroundDarkColor = UIColor.init(white: 5/255.0, alpha: 1.0)
  
  let backgroundSepiaColor = UIColor.init(red: 242/255.0, green: 228/255.0, blue: 203/255.0, alpha: 1.0)

  let backgroundMediaOverlayHighlightColor = UIColor.yellow

  let backgroundMediaOverlayHighlightDarkColor = UIColor.orange

  let backgroundMediaOverlayHighlightSepiaColor = UIColor.yellow

  // Set for the whole app via UIView+NYPLFontAdditions.
  let systemFontName = "AvenirNext-Medium"

  // Set for the whole app via UIView+NYPLFontAdditions.
  let boldSystemFontName = "AvenirNext-Bold"

  let systemFontFamilyName = "Avenir Next"
  
  var betaUrl: URL {
    return NYPLConfiguration._betaUrl
  }
  
  var prodUrl: URL {
    return NYPLConfiguration._prodUrl
  }
  
  var betaUrlHash: String {
    return NYPLConfiguration._betaUrlHash
  }
  
  var prodUrlHash: String {
    return NYPLConfiguration._prodUrlHash
  }
}
