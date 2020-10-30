//
//  NYPLReaderBookmarkBusinessLogicTests.swift
//  SimplyETests
//
//  Created by Ernest Fan on 2020-10-29.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import XCTest
import R2Shared
@testable import SimplyE

class NYPLReaderBookmarksBusinessLogicTests: XCTestCase {
    var businessLogic: NYPLReaderBookmarksBusinessLogic!
    var bookRegistryMock: NYPLBookRegistryMock!
    var libraryAccountMock: NYPLLibraryAccountMock!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        let emptyUrl = URL.init(fileURLWithPath: "")
        let fakeAcquisition = NYPLOPDSAcquisition.init(
          relation: .generic,
          type: "application/epub+zip",
          hrefURL: emptyUrl,
          indirectAcquisitions: [NYPLOPDSIndirectAcquisition](),
          availability: NYPLOPDSAcquisitionAvailabilityUnlimited.init()
        )
        let fakeBook = NYPLBook.init(
          acquisitions: [fakeAcquisition],
          bookAuthors: [NYPLBookAuthor](),
          categoryStrings: [String](),
          distributor: "",
          identifier: "fakeEpub",
          imageURL: emptyUrl,
          imageThumbnailURL: emptyUrl,
          published: Date.init(),
          publisher: "",
          subtitle: "",
          summary: "",
          title: "",
          updated: Date.init(),
          annotationsURL: emptyUrl,
          analyticsURL: emptyUrl,
          alternateURL: emptyUrl,
          relatedWorksURL: emptyUrl,
          seriesURL: emptyUrl,
          revokeURL: emptyUrl,
          report: emptyUrl
        )!
        
        bookRegistryMock = NYPLBookRegistryMock()
        libraryAccountMock = NYPLLibraryAccountMock()
        
        businessLogic = NYPLReaderBookmarksBusinessLogic(
            book: fakeBook,
            r2Publication: Publication(metadata: Metadata(title: "FakeMetadata")),
            drmDeviceID: "fakeDeviceID",
            bookRegistryProvider: bookRegistryMock,
            currentLibraryAccountProvider: libraryAccountMock)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        businessLogic = nil
        libraryAccountMock = nil
        bookRegistryMock = nil
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

}
