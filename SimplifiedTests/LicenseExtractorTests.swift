//
//  LicenseExtractorTests.swift
//  OpenEbooksTests
//
//  Created by Raman Singh on 2021-03-30.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import XCTest

class LicenseExtractorTests: XCTestCase {
    
    lazy var licenseData: Data = {
        return try! Data(contentsOf: licenseURL)
    }()
    
    lazy var licenseURL: URL = {
        return Bundle(for: LicenseExtractorTests.self)
        .url(forResource: "dummyContainer", withExtension: "xml")!
    }()
    
    func testRandomStuff() {
        do {
            let data = try Data(contentsOf: licenseURL)
            let axisXML = AxisXML(xml: NYPLXML(data: data))
            print(axisXML)
        } catch {
            print(error)
        }
        
        
    }
    
}


/*
 NYPLOPDSEntry(xml:
 NYPLXML(data:
   Data.init(contentsOf:
     Bundle.init(for: NYPLBookAcquisitionPathTests.self)
       .url(forResource: "NYPLBookAcquisitionPathEntry", withExtension: "xml")!)))
 .acquisitions;
 */
