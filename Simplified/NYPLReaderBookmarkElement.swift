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
  var progressWithinChapter:Float = 0.0
  var progressWithinBook:Float = 0.0
  
  var device:String?
  var time:String?
  
  init(annotationId:String,
       contentCFI:String,
       idref:String,
       chapter:String?,
       page:String?,
       location:String?,
       progressWithinChapter:Float,
       progressWithinBook:Float)
  {
    self.annotationId = annotationId
    self.contentCFI = contentCFI
    self.idref = idref
    self.chapter = chapter ?? ""
    self.page = page ?? ""
    self.location = location ?? ""
    self.progressWithinChapter = progressWithinChapter
    self.progressWithinBook = progressWithinBook
  }
  
  init(dictionary:NSDictionary)
  {
    self.annotationId = dictionary["annotationId"] as! String
    self.contentCFI = dictionary["contentCFI"] as! String
    self.idref = dictionary["idref"] as! String
    self.chapter = dictionary["chapter"] as? String
    self.page = dictionary["page"] as? String
    self.location = dictionary["location"] as? String
    self.time = dictionary["time"] as? String
    self.device = dictionary["device"] as? String
    if let progressChapter = dictionary["progressWithinChapter"] as? Float
    {
      self.progressWithinChapter = progressChapter
    }
    if let progressBook = dictionary["progressWithinBook"] as? Float
    {
      self.progressWithinBook = progressBook
    }
  }

  var dictionaryRepresentation:NSDictionary {
  
    return ["annotationId":self.annotationId,
            "contentCFI":self.contentCFI,
            "idref":self.idref,
            "chapter":self.chapter ?? "",
            "page":self.page ?? "",
            "location":self.location ?? "",
            "time":self.time ?? "",
            "device":self.device ?? "",
            "progressWithinChapter":self.progressWithinChapter,
            "progressWithinBook":self.progressWithinBook
            ]
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
  
  var percentInChapter:String {
    
    return (self.progressWithinChapter * 100).roundTo(decimalPlaces: 0)
    
  }
  var percentInBook:String {
    
    return (self.progressWithinBook * 100).roundTo(decimalPlaces: 0)
    
  }
}

extension Float {
  func roundTo(decimalPlaces: Int) -> String {
    return String(format: "%.\(decimalPlaces)f%%", self) as String
  }
}
