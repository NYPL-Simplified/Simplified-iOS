import XCTest

@testable import SimplyE

class LoggingTests: XCTestCase {
  
  override func setUp() {
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }
  
  func testLogRotation() {
    do {
      var size = try FileManager.default.attributesOfItem(atPath: Log.logUrl.path)[FileAttributeKey.size] as! Int
      var lastSize = size
      
      // Load the logfile up with data
      while size <= 1048576 && size >= lastSize {
        Log.info(#file, "testLogRotation: last size: \(size)")
        lastSize = size
        size = try FileManager.default.attributesOfItem(atPath: Log.logUrl.path)[FileAttributeKey.size] as! Int
      }
      
      // Check one more loop for edge case
      if size > 1048576 {
        Log.info(#file, "testLogRotation: last size: \(size)")
        lastSize = size
        size = try FileManager.default.attributesOfItem(atPath: Log.logUrl.path)[FileAttributeKey.size] as! Int
      }
      
      Log.info(#file, "testLogRotation: final size after rollover: \(size)")
      XCTAssert(size < lastSize, "Testing for filesize rollover")
    } catch {
      XCTAssert(false, "Exception in accessing log")
    }
  }
}
