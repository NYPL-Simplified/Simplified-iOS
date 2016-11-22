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
        
        let pathString = Bundle.main.path(forResource: "single_entry", ofType: "xml")
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
    
    func testExample() {
  
        let analyticsOperation = NYPLCirculationAnalyticsOperation(event: "open_book", book: self.book)
        XCTAssertNotNil(analyticsOperation)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
