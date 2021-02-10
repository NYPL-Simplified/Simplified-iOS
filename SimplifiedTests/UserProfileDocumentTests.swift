import XCTest

@testable import SimplyE

class UserProfileDocumentTests: XCTestCase {
  let validJson = NYPLFake.validUserProfileJson

  let dataCorruptedJson = "lll"
    
  let extraPropertyJson = """
  {
    "simplified:authorization_identifier": "23333999999915",
    "drm": [
      {
        "drm:vendor": "NYPL",
        "drm:scheme": "http://librarysimplified.org/terms/drm/scheme/ACS",
        "drm:clientToken": "someToken",
        "drm:testExtra":"extra property"
      }
    ],
    "links": [
      {
        "href": "https://circulation.librarysimplified.org/NYNYPL/AdobeAuth/devices",
        "rel": "http://librarysimplified.org/terms/drm/rel/devices",
        "extra": "http://librarysimplified.org/"
      }
    ],
    "simplified:authorization_expires": "2025-05-01T00:00:00Z",
    "settings": {
      "simplified:synchronize_annotations": true,
      "simplified:extra_annotations": false
    },
    "extra_property": false
  }
  """
    
  let keyNotFoundJson = """
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
        "rel": "http://librarysimplified.org/terms/drm/rel/devices"
      }
    ],
    "simplified:authorization_expires": "2025-05-01T00:00:00Z",
    "settings": {
      "simplified:synchronize_annotations": true
    }
  }
  """
    
  let mismatchTypeJson = """
    {
      "simplified:authorization_identifier": "23333999999915",
      "drm": [
        {
          "drm:vendor": "NYPL",
          "drm:scheme": "http://librarysimplified.org/terms/drm/scheme/ACS",
          "drm:clientToken": true
        }
      ],
      "links": [
        {
          "href": "https://circulation.librarysimplified.org/NYNYPL/AdobeAuth/devices",
          "rel": 123
        }
      ],
      "simplified:authorization_expires": "2025-05-01T00:00:00Z",
      "settings": {
        "simplified:synchronize_annotations": "true"
      }
    }
    """

  let valueNotFoundJson = """
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
        "href": null,
        "rel": "http://librarysimplified.org/terms/drm/rel/devices"
      }
    ],
    "simplified:authorization_expires": "2025-05-01T00:00:00Z",
    "settings": {
      "simplified:synchronize_annotations": true
    }
  }
  """

  let simply2491ProfileDoc = """
  {
    "simplified:authorization_identifier": "23333999999666",
    "drm": [{
      "drm:vendor": "NYPL",
      "drm:scheme": "http://librarysimplified.org/terms/drm/scheme/ACS",
      "drm:clientToken": "NYNYPL|1566686661|52ccc666-b666-23ea-1238-0eab1234154d|666stru4hIMzf7NRP3XhcjxfSapaNGodE2GGGGY8KGc@"
    }],
    "links": [{
      "href": "https://circulation.librarysimplified.org/NYNYPL/AdobeAuth/devices",
      "rel": "http://librarysimplified.org/terms/drm/rel/devices"
    }, {
      "href": "https://circulation.librarysimplified.org/NYNYPL/annotations/",
      "type": "application/ld+json; profile=\\"http://www.w3.org/ns/anno.jsonld\\"",
      "rel": "http://www.w3.org/ns/oa#annotationService"
    }],
    "simplified:authorization_expires": "2023-06-25T00:00:00Z",
    "settings": {
      "simplified:synchronize_annotations": null
    }
  }
  """

  /// For this test to be meaningful it needs to be run on a physical device
  /// with these global system settings:
  /// General - Language & Region:
  /// - Region: UK
  /// - Calendar: Gregorian
  /// General - Date & Time:
  /// - 24-Hour Time: Off
  func testParseProfileDocCausingSIMPLY2491() {
    guard let data = simply2491ProfileDoc.data(using: .utf8) else {
      XCTFail("Failed to generate test Data from String")
      return
    }

    do {
      let profileDoc = try UserProfileDocument.fromData(data)
      XCTAssertNotNil(profileDoc)
      XCTAssertEqual(profileDoc.authorizationIdentifier, "23333999999666")

      let cal = NSCalendar(identifier: .gregorian)!
      cal.timeZone = TimeZone(secondsFromGMT: 0)!
      cal.locale = Locale(identifier: "en_US_POSIX")
      guard let date = profileDoc.authorizationExpires else {
        XCTFail("Failed to parse `authorizationExpires`")
        return
      }
      XCTAssertEqual(cal.component(.year, from: date), 2023)
      XCTAssertEqual(cal.component(.month, from: date), 6)
      XCTAssertEqual(cal.component(.day, from: date), 25)
      XCTAssertEqual(cal.component(.hour, from: date), 0)
      XCTAssertEqual(cal.component(.minute, from: date), 0)
      XCTAssertEqual(cal.component(.second, from: date), 0)
    } catch {
      XCTFail("parse fail with error \(error)")
    }
  }

  func testParse() {
    let data = validJson.data(using: .utf8)
    XCTAssertNotNil(data)
    do {
      let pDoc = try UserProfileDocument.fromData(data!)
      
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
    
  func testParseJSONExtraProperty() {
    let data = extraPropertyJson.data(using: .utf8)
    XCTAssertNotNil(data)
    do {
      let pDoc = try UserProfileDocument.fromData(data!)
      
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
    
  func testParseJSONInvalid() {
    let data = dataCorruptedJson.data(using: .utf8)
    XCTAssertNotNil(data)
    
    do {
      let _ = try UserProfileDocument.fromData(data!)
      XCTAssert(false)
    } catch {
      let err = error as NSError
      XCTAssertEqual(err.code, NSCoderReadCorruptError)
        
      guard let customErrorCode = err.userInfo[UserProfileDocument.parseErrorKey] as? Int else {
        XCTFail()
        return
      }
      XCTAssertEqual(customErrorCode, NYPLErrorCode.parseProfileDataCorrupted.rawValue)
    }
  }
    
  func testParseJSONMissingProperty() {
    let data = keyNotFoundJson.data(using: .utf8)
    XCTAssertNotNil(data)
    
    do {
      let _ = try UserProfileDocument.fromData(data!)
      XCTAssert(false)
    } catch {
      let err = error as NSError
      XCTAssertEqual(err.code, NSCoderValueNotFoundError)
        
      guard let customErrorCode = err.userInfo[UserProfileDocument.parseErrorKey] as? Int else {
        XCTFail()
        return
      }
      XCTAssertEqual(customErrorCode, NYPLErrorCode.parseProfileKeyNotFound.rawValue)
    }
  }
    
  func testParseJSONTypeMismatch() {
    let data = mismatchTypeJson.data(using: .utf8)
    XCTAssertNotNil(data)
    
    do {
      let _ = try UserProfileDocument.fromData(data!)
      XCTAssert(false)
    } catch {
      let err = error as NSError
      XCTAssertEqual(err.code, NSCoderReadCorruptError)
        
      guard let customErrorCode = err.userInfo[UserProfileDocument.parseErrorKey] as? Int else {
        XCTFail()
        return
      }
      XCTAssertEqual(customErrorCode, NYPLErrorCode.parseProfileTypeMismatch.rawValue)
    }
  }
    
  func testParseJSONNilValue() {
    let data = valueNotFoundJson.data(using: .utf8)
    XCTAssertNotNil(data)
    
    do {
      let _ = try UserProfileDocument.fromData(data!)
      XCTAssert(false)
    } catch {
      let err = error as NSError
      XCTAssertEqual(err.code, NSCoderValueNotFoundError)
        
      guard let customErrorCode = err.userInfo[UserProfileDocument.parseErrorKey] as? Int else {
        XCTFail()
        return
      }
      XCTAssertEqual(customErrorCode, NYPLErrorCode.parseProfileValueNotFound.rawValue)
    }
  }
}
