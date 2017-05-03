//
//  NYPLReaderBookmarkElement.swift
//  Simplified
//
//  Created by Aferdita Muriqi on 4/27/17.
//  Copyright © 2017 NYPL Labs. All rights reserved.
//

import UIKit

@objc class NYPLReaderBookmarkElement: NSObject {
  
  var annotationId:String

  var contentCFI:String
  var idref:String
  
  var chapter:String?
  var page:String?
  
  var location:String?
  
  init(annotationId:String, contentCFI:String, idref:String, chapter:String?, page:String?, location:String?)
  {
    self.annotationId = annotationId
    self.contentCFI = contentCFI
    self.idref = idref
    self.chapter = chapter ?? ""
    self.page = page ?? ""
    self.location = location ?? ""
  }
  
  init(dictionary:NSDictionary)
  {
    self.annotationId = dictionary["annotationId"] as! String
    self.contentCFI = dictionary["contentCFI"] as! String
    self.idref = dictionary["idref"] as! String
    self.chapter = dictionary["chapter"] as? String
    self.page = dictionary["page"] as? String
    self.location = dictionary["location"] as? String
  }

  var dictionaryRepresentation:NSDictionary {
  
    return ["annotationId":self.annotationId,
            "contentCFI":self.contentCFI,
            "idref":self.idref,
            "chapter":self.chapter ?? "",
            "page":self.page ?? "",
            "location":self.location ?? ""]
  }
  
  override func isEqual(_ object: Any?) -> Bool {
    
    let other = object as! NYPLReaderBookmarkElement
    
    if (self.annotationId == other.annotationId &&
      self.contentCFI == other.contentCFI &&
      self.idref == other.idref &&
      self.chapter == other.chapter &&
      self.location == other.location)
    {
      return true
    }
    return false
  }
  
}
