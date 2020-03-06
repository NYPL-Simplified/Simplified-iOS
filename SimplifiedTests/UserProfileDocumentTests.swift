import XCTest

@testable import SimplyE

class UserProfileDocumentTests: XCTestCase {
  let validJson = """
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
      XCTAssertEqual(customErrorCode, NYPLErrorLogger.ErrorCode.parseProfileDataCorrupted.rawValue)
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
      XCTAssertEqual(customErrorCode, NYPLErrorLogger.ErrorCode.parseProfileKeyNotFound.rawValue)
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
      XCTAssertEqual(customErrorCode, NYPLErrorLogger.ErrorCode.parseProfileTypeMismatch.rawValue)
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
      XCTAssertEqual(customErrorCode, NYPLErrorLogger.ErrorCode.parseProfileValueNotFound.rawValue)
    }
  }
}
