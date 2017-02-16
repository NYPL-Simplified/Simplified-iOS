//
//  NYPLAnnotationsTests.swift
//  Simplified
//
//  Created by Jerry Horton on 11/21/16.
//  Copyright © 2016 NYPL Labs. All rights reserved.
//

import XCTest
@testable import SimplyE

class NYPLAnnotationsTests: XCTestCase {
    
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
    
    func testLastReadBookOperationArrayEncodeDecode() {
        
        let lastReadOperation1 = NYPLLastReadBookOperation(cfi: "page 1", book: self.book)
        XCTAssertNotNil(lastReadOperation1)
        
        let lastReadOperation2 = NYPLLastReadBookOperation(cfi: "page 2", book: self.book)
        XCTAssertNotNil(lastReadOperation2)
        
        let operationEncodeArray = [lastReadOperation1,lastReadOperation2]
        
        let file: String = "lastReadOperations.plist"
        let dir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true).first
        XCTAssertNotNil(dir)
        let path = URL(fileURLWithPath: dir!).appendingPathComponent(file)
        XCTAssertNotNil(path)
        XCTAssertTrue(NSKeyedArchiver.archiveRootObject(operationEncodeArray, toFile: (path.path)))
        let operationDecodeArray = NSKeyedUnarchiver.unarchiveObject(withFile: path.path) as! [NYPLLastReadBookOperation]
        XCTAssertNotNil(operationDecodeArray)
    }
    
}
