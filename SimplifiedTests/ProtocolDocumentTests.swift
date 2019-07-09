import XCTest

@testable import SimplyE

class ProtocolDocumentTests: XCTestCase {
  func testParse() {
    let rawJson = """
{
  "simplified:authorization_identifier": "23333999999915",
  "drm": [
    {
      "drm:vendor": "NYPL",
      "drm:scheme": "http://librarysimplified.org/terms/drm/scheme/ACS",
      "drm:clientToken": "someToken"
    }
  ],
  "links": [
    {
      "href": "https://circulation.librarysimplified.org/NYNYPL/AdobeAuth/devices",
      "rel": "http://librarysimplified.org/terms/drm/rel/devices"
    }
  ],
  "simplified:authorization_expires": "2025-05-01T00:00:00Z",
  "settings": {
    "simplified:synchronize_annotations": true
  }
}
"""
    let data = rawJson.data(using: .utf8)
    XCTAssertNotNil(data)
    do {
      let pDoc = try ProtocolDocument.fromData(data!)
      
      XCTAssert(pDoc.authorizationIdentifier == "23333999999915")
      XCTAssertNotNil(pDoc.authorizationExpires)
      print(pDoc.authorizationExpires!)
      
      // Test DRM
      XCTAssertNotNil(pDoc.drm)
      if let drms = pDoc.drm {
        XCTAssert(drms.count == 1)
        XCTAssert(drms[0].vendor == "NYPL")
        XCTAssert(drms[0].scheme == "http://librarysimplified.org/terms/drm/scheme/ACS")
        XCTAssert(drms[0].clientToken == "someToken")
        XCTAssertNil(drms[0].serverToken)
      }
      
      // Test Links
      XCTAssertNotNil(pDoc.links)
      if let links = pDoc.links {
        XCTAssert(links.count == 1)
        XCTAssert(links[0].href == "https://circulation.librarysimplified.org/NYNYPL/AdobeAuth/devices")
        XCTAssert(links[0].rel == "http://librarysimplified.org/terms/drm/rel/devices")
        XCTAssertNil(links[0].type)
        XCTAssertNil(links[0].templated)
      }
      
      // Test Settings
      XCTAssertNotNil(pDoc.settings)
      XCTAssertTrue(pDoc.settings?.synchronizeAnnotations ?? false)
    } catch {
      XCTAssert(false, error.localizedDescription)
    }
  }
}
