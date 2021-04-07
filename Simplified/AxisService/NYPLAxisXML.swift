//
//  AxisXML.swift
//  Simplified
//
//  Created by Raman Singh on 2021-04-06.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

struct NYPLAxisXML: CustomStringConvertible {
  let children: [NYPLAxisXML]
  let attributes: [AnyHashable: Any]
  let name: String
  let nameSpaceURI: String
  let qualifiedName: String
  let value: String
  
  init(xml: NYPLXML) {
    self.children = xml.children.compactMap({ $0 as? NYPLXML }).map { NYPLAxisXML(xml: $0) }
    self.attributes = xml.attributes
    self.name = xml.name
    self.nameSpaceURI = xml.namespaceURI
    self.qualifiedName = xml.qualifiedName
    self.value = xml.value
  }
  
  var description: String {
    var result = "children: \(children.map { $0.name })"
    result = result + "\nattributes: \(attributes)"
    result = result + "\nname: \(name)"
    result = result + "\nnameSpaceURI: \(nameSpaceURI)"
    result = result + "\nqualifiedName: \(qualifiedName)"
    result = result + "\nvalue: \(value)"
    return result
  }
  
  func findRecursivelyInAttributes(_ key: String) -> [String] {
    var initial: [String] = []
    if let value = self.attributes[key] as? String {
      initial.append(value)
    }
    
    let childValues = children
      .map { $0.findRecursivelyInAttributes(key)}
      .filter { !$0.isEmpty }
      .flatMap { $0 }
    
    return initial + childValues
  }
  
}
