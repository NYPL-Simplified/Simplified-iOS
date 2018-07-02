//
//  NYPLPDFBookMinitexDelegate.swift
//  SimplyE
//
//  Created by Vui Nguyen on 7/2/18.
//  Copyright © 2018 NYPL Labs. All rights reserved.
//

import Foundation
import MinitexPDFProtocols

class NYPLPDFBookMinitexDelegate: NSObject, MinitexPDFViewControllerDelegate {
  func userDidNavigate(page: Int) {
    print("userDidNavigate called")
  }

  func saveBookmarks(pageNumbers: [UInt]) {
    print("saveBookmarks called")
  }

  func saveAnnotations(annotations: [MinitexPDFAnnotation]) {
    print("saveAnnotations called")
  }
}
