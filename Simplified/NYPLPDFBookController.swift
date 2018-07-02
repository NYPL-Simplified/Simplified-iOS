//
//  NYPLPDFBookController.swift
//  SimplyE
//
//  Created by Vui Nguyen on 7/2/18.
//  Copyright © 2018 NYPL Labs. All rights reserved.
//

import Foundation
import MinitexPDFProtocols

class NYPLPDFBookController: NSObject {
  static func getPDFViewController(delegate: MinitexPDFViewControllerDelegate?, fileURL: URL?) ->
    MinitexPDFViewController? {

    print("instantiate NYPLPDFBookController")

    guard let fileURL: URL = fileURL,
      let delegate: MinitexPDFViewControllerDelegate = delegate
      else {
      return nil
    }

    let pdfDictionary: [String: Any] = [
      "PSPDFKitLicense": APIKeys.PDFLicenseKey,
      "delegate": delegate,
      "documentURL": fileURL,
      "openToPage": UInt(0),
      "bookmarks": [],
      "annotations": []
    ]

    // we should do some verification on types of dictionary so it doesn't fail
    let pdfViewController = MinitexPDFViewControllerFactory.createPDFViewController(dictionary: pdfDictionary)

    if pdfViewController != nil {
      return pdfViewController
    } else {
      print("PDF module does not exist")
      return nil
    }
  }
}
