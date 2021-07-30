import XCTest

@testable import SimplyE

class NYPLOPDSAcquisitionPathTests: XCTestCase {

  let acquisitions: [NYPLOPDSAcquisition] = try!
    NYPLOPDSEntry(xml:
      NYPLXML(data:
        Data.init(contentsOf:
          Bundle.init(for: NYPLOPDSAcquisitionPathTests.self)
            .url(forResource: "NYPLOPDSAcquisitionPathEntry", withExtension: "xml")!)))
      .acquisitions;

  func testSimplifiedAdeptEpubAcquisition() {
    let acquisitionPaths: Array<NYPLOPDSAcquisitionPath> =
      NYPLOPDSAcquisitionPath.supportedAcquisitionPaths(
        forAllowedTypes: NYPLOPDSAcquisitionPath.supportedTypes(),
        allowedRelations: [.borrow, .openAccess],
        acquisitions: acquisitions)

    #if OPENEBOOKS
    let numAcquisitionPaths = 1
    #else
    let numAcquisitionPaths = 2
    #endif

    XCTAssert(acquisitionPaths.count == numAcquisitionPaths)

    #if FEATURE_DRM_CONNECTOR
    XCTAssert(acquisitionPaths[0].relation == NYPLOPDSAcquisitionRelation.borrow)
    XCTAssert(acquisitionPaths[0].types == [
      "application/atom+xml;type=entry;profile=opds-catalog",
      "application/vnd.adobe.adept+xml",
      "application/epub+zip"
    ])
    #endif
    
    XCTAssert(acquisitionPaths[numAcquisitionPaths - 1].relation == NYPLOPDSAcquisitionRelation.borrow)
    XCTAssert(acquisitionPaths[numAcquisitionPaths - 1].types == [
      "application/atom+xml;type=entry;profile=opds-catalog",
      "application/pdf"
    ])
  }
}
