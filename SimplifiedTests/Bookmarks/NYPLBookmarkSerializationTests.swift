//
//  NYPLBookmarkSerializationTests.swift
//  Simplified
//
//  Created by Ettore Pasquini on 4/9/21.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import XCTest
import R2Shared
@testable import SimplyE

class NYPLBookmarkSerializationTests: XCTestCase {
  var bundle: Bundle!

  override func setUpWithError() throws {
    bundle = Bundle(for: NYPLBookmarkSpecTests.self)
  }

  override func tearDownWithError() throws {
    bundle = nil
  }

  func testSerializeFromR2() throws {
    let locations = Locator.Locations(progression: Double(0.666),
                                      totalProgression: Double(0.33333),
                                      position: 123)
    let locator = Locator(href: "/xyz.html",
                          type: MediaType.xhtml.string,
                          locations: locations)
    let r2Location = NYPLBookmarkR2Location(resourceIndex: 1,
                                           locator: locator)
    let factory = NYPLBookmarkFactory(publication: NYPLFake.dummyPublication,
                                      drmDeviceID: "deviceID")
    let bookmark = factory.make(fromR2Location: r2Location)
    XCTAssertNotNil(bookmark)
    XCTAssertEqual(bookmark?.progressWithinChapter, Float(locations.progression!))
    XCTAssertEqual(bookmark?.progressWithinBook, Float(locations.totalProgression!))
    XCTAssertEqual(bookmark?.href, locator.href)
  }

  func testSerializeBookmarkRoundrip() throws {
    try validateSerializationOfBookmarkFromResource("valid-bookmark-3")

    // This is a INvalid bookmark. However, by testing validation and with
    // the assumption that validation of a valid bookmark tests for all
    // mandatory keys and correct values, we can infer that if validation
    // passes the incorrect bookmark was in fact corrected before serialization.
    try validateSerializationOfBookmarkFromResource("invalid-bookmark-3")
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
      NYPLBookmarkFactory.make(fromServerAnnotation: json,
                               annotationType: motivation,
                               bookID: bookID,
                               publication: NYPLFake.dummyPublication) else {
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
    let selectorValue = serializableSelector![NYPLBookmarkSpec.Target.Selector.Value.key] as? String
    XCTAssertEqual(selectorValue?.trimmingCharacters(in: .whitespacesAndNewlines),
                   locator.trimmingCharacters(in: .whitespacesAndNewlines))

    XCTAssertEqual(serializableTarget![NYPLBookmarkSpec.Target.Source.key] as? String,
                   bookID)
  }
}
