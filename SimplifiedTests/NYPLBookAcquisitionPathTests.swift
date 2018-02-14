import XCTest

@testable import SimplyE

class NYPLBookAcquisitionPathTests: XCTestCase {

  let acquisitions: [NYPLOPDSAcquisition] = try!
    NYPLOPDSEntry(xml:
      NYPLXML(data:
        Data.init(contentsOf:
          Bundle.init(for: NYPLBookAcquisitionPathTests.self)
            .url(forResource: "NYPLBookAcquisitionPathEntry", withExtension: "xml")!)))
      .acquisitions;

  func testSimplifiedAdeptEpubAcquisition() {
    let acquisitionPaths: Set<NYPLBookAcquisitionPath> =
      NYPLBookAcquisitionPath.supportedAcquisitionPaths(
        forAllowedTypes: NYPLBookAcquisitionPath.supportedTypes(),
        allowedRelations: [.borrow, .openAccess],
        acquisitions: acquisitions)

    XCTAssert(acquisitionPaths.count == 1)

    let acquisitionPath: NYPLBookAcquisitionPath = acquisitionPaths.first!

    XCTAssert(acquisitionPath.relation == NYPLOPDSAcquisitionRelation.borrow)

    XCTAssert(acquisitionPath.types == [
      "application/atom+xml;type=entry;profile=opds-catalog",
      "application/vnd.adobe.adept+xml",
      "application/epub+zip"
    ])
  }
}
