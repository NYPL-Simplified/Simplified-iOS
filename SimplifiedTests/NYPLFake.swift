//
//  NYPLFake.swift
//  Simplified
//
//  Created by Ettore Pasquini on 10/27/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation
import R2Shared
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
    let url = bundle.url(forResource: "NYPLOPDSAcquisitionPathEntry",
                         withExtension: "xml")!
    let xml = try! NYPLXML(data: Data(contentsOf: url))
    let entry = NYPLOPDSEntry(xml: xml)
    return entry!
  }

  class var opdsEntryMinimal: NYPLOPDSEntry {
    let bundle = Bundle(for: NYPLFake.self)
    let url = bundle.url(forResource: "NYPLOPDSAcquisitionPathEntryMinimal",
                         withExtension: "xml")!
    return try! NYPLOPDSEntry(xml: NYPLXML(data: Data(contentsOf: url)))
  }

  static let validUserProfileJson = """
  {
    "simplified:authorization_identifier": "23333999999915",
    "drm": [
      {
        "drm:vendor": "NYPL",
        "drm:scheme": "http://librarysimplified.org/terms/drm/scheme/ACS",
        "drm:clientToken": "someToken"
      }
    ],
    "links": [
      {
        "href": "https://circulation.librarysimplified.org/NYNYPL/AdobeAuth/devices",
        "rel": "http://librarysimplified.org/terms/drm/rel/devices"
      }
    ],
    "simplified:authorization_expires": "2025-05-01T00:00:00Z",
    "settings": {
      "simplified:synchronize_annotations": true
    }
  }
  """

  class var dummyPublication: Publication {
    return Publication(
      manifest: Manifest(
        metadata: Metadata(title: "Title"),
        readingOrder: [
          Link(href: "chapter1", type: "text/html"),
          Link(href: "chapter2", type: "text/html")
        ]
      )
    )
  }

  class var bookmarkSpecPublication: Publication {
    return Publication(
      manifest: Manifest(
        metadata: Metadata(title: "Title"),
        readingOrder: [
          Link(href: "/xyz.html",
               type: "text/html",
               properties: Properties([
                Publication.idrefKey: "c001"
               ])),
          Link(href: "dos.html",
               type: "text/html",
               properties: Properties([
                Publication.idrefKey: "c002"
               ]))
        ]
      )
    )
  }

}
