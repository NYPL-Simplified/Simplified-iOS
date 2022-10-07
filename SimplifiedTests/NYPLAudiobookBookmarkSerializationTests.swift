//
//  NYPLAudiobookBookmarkSerializationTests.swift
//  SimplyETests
//
//  Created by Ernest Fan on 2022-10-06.
//  Copyright © 2022 NYPL. All rights reserved.
//

import XCTest
import NYPLAudiobookToolkit
import NYPLUtilities
@testable import SimplyE

class NYPLAudiobookBookmarkSerializationTests: XCTestCase {
  var bundle: Bundle!

  override func setUpWithError() throws {
    bundle = Bundle(for: NYPLAudiobookBookmarkSerializationTests.self)
  }

  override func tearDownWithError() throws {
    bundle = nil
  }

  func testSerializeAudiobookBookmarkRoundrip() throws {
    try validateSerializationOfBookmarkFromResource("valid-bookmark-4")

    // We are only testing valid bookmark here,
    // invalid bookmarks are being tested in NYPLAudiobookToolkit
  }

  /// _MUST_ check for all keys and values required by `NYPLBookmarkSpec`.
  ///
  /// - Parameter resourceName: File name only; `.json` extension is assumed.
  private func validateSerializationOfBookmarkFromResource(_ resourceName: String) throws {
    // Preconditions: the data we are reading from disk is what the server
    // may hypothetically return. From there we can create a bookmark object,
    // and then attempt to serialize that. This way we kinda simulate a
    // client-server roundtrip.
    let bookmarkURL = bundle.url(forResource: resourceName,
                                 withExtension: "json")!
    let bookmarkData = try Data(contentsOf: bookmarkURL)
    let json = try JSONSerialization.jsonObject(with: bookmarkData) as! [String: Any]
    let annotationID = json[NYPLBookmarkSpec.Id.key] as! String
    let body = json[NYPLBookmarkSpec.Body.key] as! [String: Any]
    let device = body[NYPLBookmarkSpec.Body.Device.key] as! String
    let timestamp = body[NYPLBookmarkSpec.Body.Time.key] as! String
    let target = json[NYPLBookmarkSpec.Target.key] as! [String: Any]
    let bookID = target[NYPLBookmarkSpec.Target.Source.key] as! String
    let selector = target[NYPLBookmarkSpec.Target.Selector.key] as! [String: Any]
    let locator = selector[NYPLBookmarkSpec.Target.Selector.Value.key] as! String

    let motivationString = json[NYPLBookmarkSpec.Motivation.key] as! String
    let motivation = NYPLBookmarkSpec.Motivation(rawValue: motivationString)!

    guard let bookmark =
            NYPLAudiobookBookmarkFactory.make(fromServerAnnotation: json,
                                              selectorValueParser: NYPLBookmarkFactory.self,
                                              annotationType: motivation,
                                              bookID: bookID) else {
                                        XCTFail("Failed to create bookmark from valid data")
                                        return
    }

    // test
    let serializableDict = bookmark
      .serializableRepresentation(forMotivation: motivation, bookID: bookID)

    let serializedData = NYPLAnnotations
      .makeSubmissionData(fromRepresentation: serializableDict)

    // verify
    XCTAssertNotNil(serializedData)

    // Kind of a heuristic. Data read from disk and serialized data might not
    // be identical byte-by-byte and might have slightly different size.
    // A bookmark dictionary has roughly 20 lines. If we account for roughly
    // +/- 6 space difference per line, we can say that the size should match
    // with +/- 120 bytes difference.
    XCTAssertLessThan(abs((serializedData?.count ?? 0) - bookmarkData.count), 120)

    XCTAssertEqual(serializableDict[NYPLBookmarkSpec.Context.key] as? String,
                   NYPLBookmarkSpec.Context.value)
    XCTAssertEqual(serializableDict[NYPLBookmarkSpec.type.key] as? String,
                   NYPLBookmarkSpec.type.value)
    XCTAssertEqual(serializableDict[NYPLBookmarkSpec.Id.key] as? String,
                   annotationID)
    XCTAssertEqual(serializableDict[NYPLBookmarkSpec.Motivation.key] as? String,
                   motivation.rawValue)

    let serializableBody = serializableDict[NYPLBookmarkSpec.Body.key] as? [String: Any]
    XCTAssertNotNil(serializableBody)
    XCTAssertEqual(serializableBody![NYPLBookmarkSpec.Body.Time.key] as? String,
                   timestamp)
    XCTAssertEqual(serializableBody![NYPLBookmarkSpec.Body.Device.key] as? String,
                   device)

    let serializableTarget = serializableDict[NYPLBookmarkSpec.Target.key] as? [String: Any]
    XCTAssertNotNil(serializableTarget)

    let serializableSelector = serializableTarget![NYPLBookmarkSpec.Target.Selector.key] as? [String: Any]
    XCTAssertNotNil(serializableSelector)
    XCTAssertEqual(serializableSelector![NYPLBookmarkSpec.Target.Selector.type.key] as? String,
                   NYPLBookmarkSpec.Target.Selector.type.value)
    
    guard let selectorValueString = serializableSelector![NYPLBookmarkSpec.Target.Selector.Value.key] as? String,
          let selectorValue = NYPLAudiobookBookmarkFactory.parseLocatorString(selectorValueString),
          let locatorValue = NYPLAudiobookBookmarkFactory.parseLocatorString(locator) else {
      XCTFail("Failed to fetch/parse selector value")
      return
    }
    XCTAssertEqual(selectorValue.part, locatorValue.part)
    XCTAssertEqual(selectorValue.chapter, locatorValue.chapter)
    XCTAssertEqual(selectorValue.duration, locatorValue.duration)
    XCTAssertEqual(selectorValue.time, locatorValue.time)
    XCTAssertEqual(selectorValue.audiobookId, locatorValue.audiobookId)
    XCTAssertEqual(selectorValue.title, locatorValue.title)

    XCTAssertEqual(serializableTarget![NYPLBookmarkSpec.Target.Source.key] as? String,
                   bookID)
  }
}
