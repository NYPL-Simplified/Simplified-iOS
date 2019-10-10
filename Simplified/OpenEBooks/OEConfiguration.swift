import HelpStack

class OEConfiguration : NYPLConfiguration {
  static let NYPLCirculationBaseURLProduction = "https://circulation.openebooks.us"
  static let NYPLCirculationBaseURLTesting = "http://qa.circulation.openebooks.us"
  static let OpenEBooksUUID = "urn:uuid:e1a01c16-04e7-4781-89fd-b442dd1be001"
  
  fileprivate static let _dummyUrl = URL.init(fileURLWithPath: Bundle.main.path(forResource: "OpenEBooks_OPDS2_Catalog_Feed", ofType: "json")!)
  fileprivate static let _dummyUrlHash = _dummyUrl.absoluteString.md5().base64EncodedStringUrlSafe().trimmingCharacters(in: ["="])
  
  static var oeShared = OEConfiguration()
  
  let openEBooksRequestCodesURL = URL.init(string: "http://openebooks.net/getstarted.html")!
  let circulationURL = URL.init(string: NYPLCirculationBaseURLProduction)!
  
  // MARK: NYPLConfiguration
  
  override class func initConfig() {
    super.initConfig()
    
    // HelpStack ZenDesk
    let hs = HSHelpStack.instance() as! HSHelpStack
    hs.setThemeFrompList("HelpStackTheme")
    let zenDeskGear = HSZenDeskGear.init(
      instanceUrl: "https://openebooks.zendesk.com",
      staffEmailAddress: "jamesenglish@nypl.org",
      apiToken: "mgNmqzUFmNoj9oTBmDdtDVGYdm1l0HqWgZIZlQcN"
    )
    hs.gear = zenDeskGear
  }
  
  override var betaUrl: URL {
    return OEConfiguration._dummyUrl
  }
  
  override var prodUrl: URL {
    return OEConfiguration._dummyUrl
  }
  
  override var betaUrlHash: String {
    return OEConfiguration._dummyUrlHash
  }
  
  override var prodUrlHash: String {
    return OEConfiguration._dummyUrlHash
  }
  
  override var mainColor: UIColor {
    return UIColor.init(red: 141.0/255.0, green: 199.0/255.0, blue: 64.0/255.0, alpha: 1.0)
  }
}
