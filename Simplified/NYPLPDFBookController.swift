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
  static func getPDFViewController(bookIdentifier: String?, delegate: MinitexPDFViewControllerDelegate?, fileURL: URL?) ->
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

    guard let pdfViewController: UIViewController = MinitexPDFViewControllerFactory.createPDFViewController(dictionary: pdfDictionary) as? UIViewController else {
        print("PDF module does not exist")
        return nil
    }

    // have the PDF renderer cover the entire screen
    pdfViewController.hidesBottomBarWhenPushed = true;

    // mark the book as having been read
    NYPLBookRegistry.shared().setState(NYPLBookState.used, forIdentifier: bookIdentifier)

    return pdfViewController as? MinitexPDFViewController
  }
}
