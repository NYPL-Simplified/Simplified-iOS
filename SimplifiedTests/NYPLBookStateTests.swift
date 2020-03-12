import XCTest

@testable import SimplyE

class NYPLBookStateTests: XCTestCase {
    
    func testInitWithString() {
      XCTAssertEqual(NYPLBookState.Unregistered, NYPLBookState.init(UnregisteredKey))
      XCTAssertEqual(NYPLBookState.DownloadNeeded, NYPLBookState.init(DownloadNeededKey))
      XCTAssertEqual(NYPLBookState.Downloading, NYPLBookState.init(DownloadingKey))
      XCTAssertEqual(NYPLBookState.DownloadFailed, NYPLBookState.init(DownloadFailedKey))
      XCTAssertEqual(NYPLBookState.DownloadSuccessful, NYPLBookState.init(DownloadSuccessfulKey))
      XCTAssertEqual(NYPLBookState.Holding, NYPLBookState.init(HoldingKey))
      XCTAssertEqual(NYPLBookState.Used, NYPLBookState.init(UsedKey))
      XCTAssertEqual(NYPLBookState.Unsupported, NYPLBookState.init(UnsupportedKey))
      XCTAssertEqual(nil, NYPLBookState.init("InvalidKey"))
    }
    
    func testStringValue() {
      XCTAssertEqual(NYPLBookState.Unregistered.stringValue(), UnregisteredKey)
      XCTAssertEqual(NYPLBookState.DownloadNeeded.stringValue(), DownloadNeededKey)
      XCTAssertEqual(NYPLBookState.Downloading.stringValue(), DownloadingKey)
      XCTAssertEqual(NYPLBookState.DownloadFailed.stringValue(), DownloadFailedKey)
      XCTAssertEqual(NYPLBookState.DownloadSuccessful.stringValue(), DownloadSuccessfulKey)
      XCTAssertEqual(NYPLBookState.Holding.stringValue(), HoldingKey)
      XCTAssertEqual(NYPLBookState.Used.stringValue(), UsedKey)
      XCTAssertEqual(NYPLBookState.Unsupported.stringValue(), UnsupportedKey)
    }
    
    func testBookStateFromString() {
      XCTAssertEqual(NYPLBookState.Unregistered.rawValue, NYPLBookStateHelper.bookState(fromString: UnregisteredKey))
      XCTAssertEqual(NYPLBookState.DownloadNeeded.rawValue, NYPLBookStateHelper.bookState(fromString: DownloadNeededKey))
      XCTAssertEqual(NYPLBookState.Downloading.rawValue, NYPLBookStateHelper.bookState(fromString: DownloadingKey))
      XCTAssertEqual(NYPLBookState.DownloadFailed.rawValue, NYPLBookStateHelper.bookState(fromString: DownloadFailedKey))
      XCTAssertEqual(NYPLBookState.DownloadSuccessful.rawValue, NYPLBookStateHelper.bookState(fromString: DownloadSuccessfulKey))
      XCTAssertEqual(NYPLBookState.Holding.rawValue, NYPLBookStateHelper.bookState(fromString: HoldingKey))
      XCTAssertEqual(NYPLBookState.Used.rawValue, NYPLBookStateHelper.bookState(fromString: UsedKey))
      XCTAssertEqual(NYPLBookState.Unsupported.rawValue, NYPLBookStateHelper.bookState(fromString: UnsupportedKey))
      XCTAssertEqual(-1, NYPLBookStateHelper.bookState(fromString: "InvalidString"))
    }
    
    func testAllBookState() {
        XCTAssertEqual(NYPLBookStateHelper.allBookStates(), NYPLBookState.allCases.map{ $0.rawValue })
    }
}
