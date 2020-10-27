//
//  NYPLFakeSamples.swift
//  Simplified
//
//  Created by Ettore Pasquini on 10/27/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation
@testable import SimplyE

class NYPLFake {
  class var genericAcquisition: NYPLOPDSAcquisition {
    return NYPLOPDSAcquisition(
      relation: .generic,
      type: "application/epub+zip",
      hrefURL: URL(fileURLWithPath: ""),
      indirectAcquisitions: [NYPLOPDSIndirectAcquisition](),
      availability: NYPLOPDSAcquisitionAvailabilityUnlimited()
    )
  }

  class var opdsEntry: NYPLOPDSEntry {
    let bundle = Bundle(for: NYPLFake.self)
    let url = bundle.url(forResource: "NYPLBookAcquisitionPathEntry",
                         withExtension: "xml")!
    let xml = try! NYPLXML(data: Data(contentsOf: url))
    let entry = NYPLOPDSEntry(xml: xml)
    return entry!
  }

  class var opdsEntryMinimal: NYPLOPDSEntry {
    let bundle = Bundle(for: NYPLFake.self)
    let url = bundle.url(forResource: "NYPLBookAcquisitionPathEntryMinimal",
                         withExtension: "xml")!
    return try! NYPLOPDSEntry(xml: NYPLXML(data: Data(contentsOf: url)))
  }
}
