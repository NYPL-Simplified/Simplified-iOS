//
//  NYPLAxisXMLCreator.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-06-23.
//  Copyright © 2021 NYPL. All rights reserved.
//

import Foundation
import NYPLAxis

struct NYPLAxisXMLCreator: NYPLAxisXMLCreating {
  
  func createAxisXML(from data: Data?) -> NYPLAxisXML? {
    return NYPLAxisXMLRepresentation(data: data)
  }

}


