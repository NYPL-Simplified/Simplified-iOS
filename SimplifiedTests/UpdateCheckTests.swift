import XCTest

class UpdateCheckTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
  }
  
  override func tearDown() {
    super.tearDown()
  }
  
  func testUpToDate() {
    let URL = NSBundle(forClass: UpdateCheckTests.self).URLForResource("UpdateCheckUpToDate", withExtension: "json")!
    
    let expectation = expectationWithDescription("performUpdateCheck")
    
    UpdateCheck.performUpdateCheck(URL) { (result: UpdateCheck.Result) in
      switch result {
      case .UpToDate:
        break
      default:
        XCTFail("Not up-to-date.")
      }
      expectation.fulfill()
    }
    
    waitForExpectationsWithTimeout(1.0, handler: nil)
  }
  
  func testNeedsUpdate() {
    let URL = NSBundle(forClass: UpdateCheckTests.self).URLForResource("UpdateCheckNeedsUpdate", withExtension: "json")!
    
    let expectation = expectationWithDescription("performUpdateCheck")
    
    UpdateCheck.performUpdateCheck(URL) { (result: UpdateCheck.Result) in
      switch result {
      case .NeedsUpdate:
        break
      default:
        XCTFail("Does not need update.")
      }
      expectation.fulfill()
    }
    
    waitForExpectationsWithTimeout(1.0, handler: nil)
  }
  
  func testUnknown0() {
    let URL = NSBundle(forClass: UpdateCheckTests.self).URLForResource("UpdateCheckUnknown", withExtension: "json")!
    
    let expectation = expectationWithDescription("performUpdateCheck")
    
    UpdateCheck.performUpdateCheck(URL) { (result: UpdateCheck.Result) in
      switch result {
      case .Unknown:
        break
      default:
        XCTFail("Is not unknown.")
      }
      expectation.fulfill()
    }
    
    waitForExpectationsWithTimeout(1.0, handler: nil)
  }
  
  func testUnknown1() {
    let URL = NSURL(string: "http://a2b21063-3cef-47a2-94b7-6941c97d3259.com/does-not-exist")!
    
    let expectation = expectationWithDescription("performUpdateCheck")
    
    UpdateCheck.performUpdateCheck(URL) { (result: UpdateCheck.Result) in
      switch result {
      case .Unknown:
        break
      default:
        XCTFail("Is not unknown.")
      }
      expectation.fulfill()
    }
    
    waitForExpectationsWithTimeout(1.0, handler: nil)
  }
}
