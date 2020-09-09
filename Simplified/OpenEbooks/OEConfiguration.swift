//
//  OEConfiguration.swift
//  Open eBooks
//
//  Created by Kyle Sakai.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

//import HelpStack

class OEConfiguration : NYPLConfiguration {
  static let NYPLCirculationBaseURLProduction = "https://circulation.openebooks.us"
  static let NYPLCirculationBaseURLTesting = "http://qa.circulation.openebooks.us"
  static let OpenEBooksUUID = "urn:uuid:e1a01c16-04e7-4781-89fd-b442dd1be001"
  
  private static let _dummyUrl = URL.init(fileURLWithPath: Bundle.main.path(forResource: "OpenEBooks_OPDS2_Catalog_Feed", ofType: "json")!)
  private static let _dummyUrlHash = _dummyUrl.absoluteString.md5().base64EncodedStringUrlSafe().trimmingCharacters(in: ["="])
  
  static var oeShared = OEConfiguration()
  
  let openEBooksRequestCodesURL = URL(string: "http://openebooks.net/getstarted.html")!
  let circulationURL = URL(string: NYPLCirculationBaseURLProduction)!

//  override class func initConfig() {
//    super.initConfig()
//
// TODO: SIMPLY-3051 figure out if we still want HelpStack
//    // HelpStack ZenDesk
//    let hs = HSHelpStack.instance() as! HSHelpStack
//    hs.setThemeFrompList("HelpStackTheme")
//    let zenDeskGear = HSZenDeskGear.init(
//      instanceUrl: "https://openebooks.zendesk.com",
//      staffEmailAddress: "jamesenglish@nypl.org",
//      apiToken: "mgNmqzUFmNoj9oTBmDdtDVGYdm1l0HqWgZIZlQcN"
//    )
//    hs.gear = zenDeskGear
//  }
  
  var betaUrl: URL {
    return OEConfiguration._dummyUrl
  }
  
  var prodUrl: URL {
    return OEConfiguration._dummyUrl
  }
  
  var betaUrlHash: String {
    return OEConfiguration._dummyUrlHash
  }
  
  var prodUrlHash: String {
    return OEConfiguration._dummyUrlHash
  }
  
  static var mainColor: UIColor {
    return UIColor(red: 141.0/255.0, green: 199.0/255.0, blue: 64.0/255.0, alpha: 1.0)
  }
}
