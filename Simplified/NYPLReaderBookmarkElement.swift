//
//  NYPLReaderBookmarkElement.swift
//  Simplified
//
//  Created by Aferdita Muriqi on 4/27/17.
//  Copyright © 2017 NYPL Labs. All rights reserved.
//

import UIKit

@objc class NYPLReaderBookmarkElement: NSObject {
  
  var annotationId:String?

  var contentCFI:String
  var idref:String
  
  var chapter:String
  var page:String?
  
  init(annotationId:String?, contentCFI:String, idref:String, chapter:String, page:String?)
  {
    self.annotationId = annotationId
    self.contentCFI = contentCFI
    self.idref = idref
    self.chapter = chapter
    self.page = page
  }
  
  
}
