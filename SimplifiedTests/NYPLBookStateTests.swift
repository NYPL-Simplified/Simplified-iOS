import XCTest

@testable import SimplyE

class NYPLBookStateTests: XCTestCase {
    
    func testInitWithString() {
      XCTAssertEqual(NYPLBookState.Unregistered, NYPLBookState.init(UnregisteredKey))
      XCTAssertEqual(NYPLBookState.DownloadNeeded, NYPLBookState.init(DownloadNeededKey))
      XCTAssertEqual(NYPLBookState.Downloading, NYPLBookState.init(DownloadingKey))
      XCTAssertEqual(NYPLBookState.DownloadingUsable, NYPLBookState.init(DownloadingUsableKey))
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
      XCTAssertEqual(NYPLBookState.DownloadingUsable.stringValue(), DownloadingUsableKey)
      XCTAssertEqual(NYPLBookState.DownloadFailed.stringValue(), DownloadFailedKey)
      XCTAssertEqual(NYPLBookState.DownloadSuccessful.stringValue(), DownloadSuccessfulKey)
      XCTAssertEqual(NYPLBookState.Holding.stringValue(), HoldingKey)
      XCTAssertEqual(NYPLBookState.Used.stringValue(), UsedKey)
      XCTAssertEqual(NYPLBookState.Unsupported.stringValue(), UnsupportedKey)
    }
    
    func testBookStateFromString() {
      XCTAssertEqual(NYPLBookState.Unregistered.rawValue, NYPLBookStateHelper.bookState(fromString: UnregisteredKey)?.intValue)
      XCTAssertEqual(NYPLBookState.DownloadNeeded.rawValue, NYPLBookStateHelper.bookState(fromString: DownloadNeededKey)?.intValue)
      XCTAssertEqual(NYPLBookState.Downloading.rawValue, NYPLBookStateHelper.bookState(fromString: DownloadingKey)?.intValue)
      XCTAssertEqual(NYPLBookState.DownloadingUsable.rawValue, NYPLBookStateHelper.bookState(fromString: DownloadingUsableKey)?.intValue)
      XCTAssertEqual(NYPLBookState.DownloadFailed.rawValue, NYPLBookStateHelper.bookState(fromString: DownloadFailedKey)?.intValue)
      XCTAssertEqual(NYPLBookState.DownloadSuccessful.rawValue, NYPLBookStateHelper.bookState(fromString: DownloadSuccessfulKey)?.intValue)
      XCTAssertEqual(NYPLBookState.Holding.rawValue, NYPLBookStateHelper.bookState(fromString: HoldingKey)?.intValue)
      XCTAssertEqual(NYPLBookState.Used.rawValue, NYPLBookStateHelper.bookState(fromString: UsedKey)?.intValue)
      XCTAssertEqual(NYPLBookState.Unsupported.rawValue, NYPLBookStateHelper.bookState(fromString: UnsupportedKey)?.intValue)
      XCTAssertNil(NYPLBookStateHelper.bookState(fromString: "InvalidString"))
    }
    
    func testAllBookState() {
        XCTAssertEqual(NYPLBookStateHelper.allBookStates(), NYPLBookState.allCases.map{ $0.rawValue })
    }
}
