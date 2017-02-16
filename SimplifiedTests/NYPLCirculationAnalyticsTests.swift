//
//  NYPLCirculationAnalyticsTests.swift
//  Simplified
//
//  Created by Jerry Horton on 11/21/16.
//  Copyright © 2016 NYPL Labs. All rights reserved.
//

import XCTest
@testable import SimplyE

class NYPLCirculationAnalyticsTests: XCTestCase {
    
    var book: NYPLBook!
    var entry: NYPLOPDSEntry!
    
    override func setUp() {
        super.setUp()
        
        let pathString = Bundle(for: type(of: self)).path(forResource: "single_entry", ofType: "xml")
        XCTAssertNotNil(pathString)
        let data = NSData( contentsOfFile: pathString!)
        XCTAssertNotNil(data)
        
        let feedXML: NYPLXML = NYPLXML(data: data as Data!)
        XCTAssertNotNil(feedXML)
        
        let feed: NYPLOPDSFeed = NYPLOPDSFeed.init(xml: feedXML)
        XCTAssertNotNil(feed)
        
        let entries = feed.entries as! [NYPLOPDSEntry]
        XCTAssertNotNil(entries)
        
        self.entry = entries[0]
        XCTAssertNotNil(self.entry)
        
        self.book = NYPLBook.init(entry: self.entry)
        XCTAssertNotNil(self.book)
      
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCirculationAnalyticOperationArrayEncodeDecode() {
  
        let analyticsOperation1 = NYPLCirculationAnalyticsOperation(event: "open_book", book: self.book)
        XCTAssertNotNil(analyticsOperation1)
    
        let analyticsOperation2 = NYPLCirculationAnalyticsOperation(event: "close_book", book: self.book)
        XCTAssertNotNil(analyticsOperation2)
        
        let operationEncodeArray = [analyticsOperation1,analyticsOperation2]
        
        let file: String = "analyticsOperations.plist"
        let dir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true).first
        XCTAssertNotNil(dir)
        let path = URL(fileURLWithPath: dir!).appendingPathComponent(file)
        XCTAssertNotNil(path)
        XCTAssertTrue(NSKeyedArchiver.archiveRootObject(operationEncodeArray, toFile: (path.path)))
        let operationDecodeArray = NSKeyedUnarchiver.unarchiveObject(withFile: path.path) as! [NYPLCirculationAnalyticsOperation]
        XCTAssertNotNil(operationDecodeArray)
    }
    
    
}
