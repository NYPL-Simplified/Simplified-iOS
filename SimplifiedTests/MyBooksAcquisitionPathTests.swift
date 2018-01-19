import XCTest

@testable import SimplyE

class MyBooksAcquisitionPathTests: XCTestCase {

  let acquisitions: [NYPLOPDSAcquisition] = try!
    NYPLOPDSEntry(xml:
      NYPLXML(data:
        Data.init(contentsOf:
          Bundle.init(for: MyBooksAcquisitionPathTests.self)
            .url(forResource: "MyBooksAcquisitionPathEntry", withExtension: "xml")!)))
      .acquisitions;

  func testSimplifiedAdeptEpubAcquisition() {
    let acquisitionPaths: Set<NYPLMyBooksAcquisitionPath> =
      NYPLMyBooksAcquisitionPath.supportedAcquisitionPaths(
        forAllowedTypes: NYPLMyBooksAcquisitionPath.supportedTypes(),
        allowedRelations: [.borrow, .openAccess],
        acquisitions: acquisitions)

    XCTAssert(acquisitionPaths.count == 1)

    let acquisitionPath: NYPLMyBooksAcquisitionPath = acquisitionPaths.first!

    XCTAssert(acquisitionPath.relation == NYPLOPDSAcquisitionRelation.borrow)

    XCTAssert(acquisitionPath.types == [
      "application/atom+xml;type=entry;profile=opds-catalog",
      "application/vnd.adobe.adept+xml",
      "application/epub+zip"
    ])
  }
}
