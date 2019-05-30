import XCTest

@testable import SimplyE

class NYPLMyBooksDownloadCenterTests: XCTestCase {
  func testDeleteBook() {
    let fileManager = FileManager.default
    let emptyUrl = URL.init(fileURLWithPath: "")
    let configs = [
      [
        "identifier": "fakeEpub",
        "type": "application/epub+zip",
      ],
      // It looks like audiobooks are handled very differently
      // [
      //   "identifier": "fakeAudiobook",
      //   "type": "application/audiobook+json",
      // ],
      [
        "identifier": "fakePdf",
        "type": "application/pdf",
      ]
    ]
    for config in configs {
      let fakeAcquisition = NYPLOPDSAcquisition.init(
        relation: .generic,
        type: config["type"]!,
        hrefURL: emptyUrl,
        indirectAcquisitions: [NYPLOPDSIndirectAcquisition](),
        availability: NYPLOPDSAcquisitionAvailabilityUnlimited.init()
      )
      let fakeBook = NYPLBook.init(
        acquisitions: [fakeAcquisition],
        bookAuthors: [NYPLBookAuthor](),
        categoryStrings: [String](),
        distributor: "",
        identifier: config["identifier"],
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
      )
      let bookUrl = NYPLMyBooksDownloadCenter.shared()?.fileURL(forBookIndentifier: fakeBook?.identifier)
      fileManager.createFile(atPath: bookUrl!.path, contents: "Hello world!".data(using: .utf8), attributes: [FileAttributeKey : Any]())
      NYPLBookRegistry.shared()?.add(
        fakeBook,
        location: NYPLBookLocation.init(locationString: bookUrl?.path, renderer: ""),
        state: .init(),
        fulfillmentId: "",
        readiumBookmarks: [NYPLReadiumBookmark](),
        genericBookmarks: [NYPLBookLocation]()
      )
      XCTAssert(fileManager.fileExists(atPath: bookUrl!.path))
      NYPLMyBooksDownloadCenter.shared()?.deleteLocalContent(forBookIdentifier: fakeBook?.identifier)
      XCTAssert(!fileManager.fileExists(atPath: bookUrl!.path))
    }
  }
}
