import XCTest

@testable import SimplyE

class NYPLOPDSAcquisitionPathTests: XCTestCase {

  let acquisitions: [NYPLOPDSAcquisition] = try!
    NYPLOPDSEntry(xml:
      NYPLXML(data:
        Data.init(contentsOf:
          Bundle.init(for: NYPLOPDSAcquisitionPathTests.self)
            .url(forResource: "MyBooksAcquisitionPathEntry", withExtension: "xml")!)))
      .acquisitions;

  func testSimplifiedAdeptEpubAcquisition() {
    let acquisitionPaths: Set<NYPLOPDSAcquisitionPath> =
      NYPLOPDSAcquisitionPath.supportedAcquisitionPaths(
        forAllowedTypes: NYPLOPDSAcquisitionPath.supportedTypes(),
        allowedRelations: [.borrow, .openAccess],
        acquisitions: acquisitions)

    XCTAssert(acquisitionPaths.count == 1)

    let acquisitionPath: NYPLOPDSAcquisitionPath = acquisitionPaths.first!

    XCTAssert(acquisitionPath.relation == NYPLOPDSAcquisitionRelation.borrow)

    XCTAssert(acquisitionPath.types == [
      "application/atom+xml;type=entry;profile=opds-catalog",
      "application/vnd.adobe.adept+xml",
      "application/epub+zip"
    ])
  }
}
