//
//  NSString+JSONParse.swift
//  Simplified
//
//  Created by Jacek Szyja on 10/07/2020.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

extension NSString {

  @objc var parseJSONString: AnyObject? {

    let data = self.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false)

    if let jsonData = data {
      // Will return an object or nil if JSON decoding fails
      return try! JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.mutableContainers) as AnyObject?
    } else {
      // Lossless conversion of the string was not possible
      return nil
    }
  }
}
