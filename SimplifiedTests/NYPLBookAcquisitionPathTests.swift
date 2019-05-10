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
    let acquisitionPaths: Array<NYPLBookAcquisitionPath> =
      NYPLBookAcquisitionPath.supportedAcquisitionPaths(
        forAllowedTypes: NYPLBookAcquisitionPath.supportedTypes(),
        allowedRelations: [.borrow, .openAccess],
        acquisitions: acquisitions)

    XCTAssert(acquisitionPaths.count == 2)

    XCTAssert(acquisitionPaths[0].relation == NYPLOPDSAcquisitionRelation.borrow)
    XCTAssert(acquisitionPaths[0].types == [
      "application/atom+xml;type=entry;profile=opds-catalog",
      "application/vnd.adobe.adept+xml",
      "application/epub+zip"
    ])
    
    XCTAssert(acquisitionPaths[1].relation == NYPLOPDSAcquisitionRelation.borrow)
    XCTAssert(acquisitionPaths[1].types == [
      "application/atom+xml;type=entry;profile=opds-catalog",
      "application/pdf"
      ])
  }
}
