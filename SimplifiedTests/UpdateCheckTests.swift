import XCTest

@testable import SimplyE;

class UpdateCheckTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
  }
  
  override func tearDown() {
    super.tearDown()
  }
  
  func testUpToDate() {
    let URL = Bundle(for: UpdateCheckTests.self).url(forResource: "UpdateCheckUpToDate", withExtension: "json")!
    
    let expectation = self.expectation(description: "performUpdateCheck")
    
    UpdateCheck.performUpdateCheck(URL) { (result: UpdateCheck.Result) in
      switch result {
      case .upToDate:
        break
      default:
        XCTFail("Not up-to-date.")
      }
      expectation.fulfill()
    }
    
    waitForExpectations(timeout: 2.0, handler: nil)
  }
  
  func testNeedsUpdate() {
    let URL = Bundle(for: UpdateCheckTests.self).url(forResource: "UpdateCheckNeedsUpdate", withExtension: "json")!
    
    let expectation = self.expectation(description: "performUpdateCheck")
    
    UpdateCheck.performUpdateCheck(URL) { (result: UpdateCheck.Result) in
      switch result {
      case .needsUpdate:
        break
      default:
        XCTFail("Does not need update.")
      }
      expectation.fulfill()
    }
    
    waitForExpectations(timeout: 2.0, handler: nil)
  }
  
  func testUnknown0() {
    let URL = Bundle(for: UpdateCheckTests.self).url(forResource: "UpdateCheckUnknown", withExtension: "json")!
    
    let expectation = self.expectation(description: "performUpdateCheck")
    
    UpdateCheck.performUpdateCheck(URL) { (result: UpdateCheck.Result) in
      switch result {
      case .unknown:
        break
      default:
        XCTFail("Is not unknown.")
      }
      expectation.fulfill()
    }
    
    waitForExpectations(timeout: 2.0, handler: nil)
  }
  
  func testUnknown1() {
    let URL = Foundation.URL(string: "http://a2b21063-3cef-47a2-94b7-6941c97d3259.com/does-not-exist")!
    
    let expectation = self.expectation(description: "performUpdateCheck")
    
    UpdateCheck.performUpdateCheck(URL) { (result: UpdateCheck.Result) in
      switch result {
      case .unknown:
        break
      default:
        XCTFail("Is not unknown.")
      }
      expectation.fulfill()
    }
    
    waitForExpectations(timeout: 2.0, handler: nil)
  }
}
