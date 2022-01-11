//
//  AxisXML.swift
//  Simplified
//
//  Created by Raman Singh on 2021-04-06.
//  Copyright © 2021 NYPL. All rights reserved.
//

import Foundation
import NYPLAxis

/// A wrapper class which aids debugging and allows recursive search with a given key in an NYPLXML object.
struct NYPLAxisXMLRepresentation: CustomStringConvertible {
  let children: [NYPLAxisXML]
  let attributes: [AnyHashable: Any]
  let name: String
  let nameSpaceURI: String
  let qualifiedName: String
  let value: String
  
  // MARK: - Static Constants
  static private let summary = "AXIS: Failed to generate AXISXML from data"
  static let NYPLXMLGenerationFailure = "Failed generating NYPL XML from data"
  
  init(xml: NYPLXML) {
    self.children = xml.children.compactMap({ $0 as? NYPLXML }).map { NYPLAxisXMLRepresentation(xml: $0) }
    self.attributes = xml.attributes
    self.name = xml.name
    self.nameSpaceURI = xml.namespaceURI
    self.qualifiedName = xml.qualifiedName
    self.value = xml.value
  }
  
  /// Failable initializer for AXISXML. Returns nil if data is nil or NYPLXML initialization fails. Logs erron on
  /// failure
  init?(data: Data?) {
    guard let data = data else {
      NYPLErrorLogger.logError(
        withCode: .axisDRMFulfillmentFail,
        summary: NYPLAxisXMLRepresentation.summary,
        metadata: [NYPLAxisService.reason: NYPLAxisService.nilDataFromFileURLFailure])
      
      return nil
    }
    
    guard let xml = NYPLXML(data: data) else {
        NYPLErrorLogger.logError(
          withCode: .axisDRMFulfillmentFail,
          summary: NYPLAxisXMLRepresentation.summary,
          metadata: [NYPLAxisService.reason: NYPLAxisXMLRepresentation.NYPLXMLGenerationFailure])
        
        return nil
    }
    
    self.init(xml: xml)
  }
  
  /// For debugging purposes
  var description: String {
    var result = "children: \(children.map { $0.name })"
    result = result + "\nattributes: \(attributes)"
    result = result + "\nname: \(name)"
    result = result + "\nnameSpaceURI: \(nameSpaceURI)"
    result = result + "\nqualifiedName: \(qualifiedName)"
    result = result + "\nvalue: \(value)"
    return result
  }
}

extension NYPLAxisXMLRepresentation: NYPLAxisXML {
  /// Finds the first node whose name matches the given key.
  ///
  /// Space complexity (worst case): O(n)
  /// Time complexity (worst case): O(n)
  ///
  /// - Parameter nodeName: the name of node to look for.
  /// - Returns: an XML whose `name` matches the given `key`.
  ///
  func firstNodeNamed(_ nodeName: String) -> NYPLAxisXML? {
    // Tail recursive breadth-first implementation
    func find(in q: inout [NYPLAxisXML]) -> NYPLAxisXML? {
      if q.isEmpty {
        return nil
      }

      let node = q.removeFirst()
      if node.name == nodeName {
        return node
      }

      q.append(contentsOf: node.children)

      return find(in: &q)
    }

    var q = [self as NYPLAxisXML]
    return find(in: &q)
  }
  
  /// Gathers all attributes values for the given key searching only the first
  /// level children matching a given name.
  ///
  /// - Parameters:
  ///   - key: Attribute key to look for.
  ///   - nodeName: Name of the nodes where to look for the given attribute key.
  ///
  /// - Returns: An array of values for the specified key. Returns an empty
  /// array if nothing matching was found.
  func attributeValues(forKey key: String, onNodesNamed nodeName: String) -> [String] {
    let values = children
      .filter { $0.name == nodeName }
      .compactMap { $0.attributes[key] as? String }
      .filter { !$0.isEmpty }
    
    return values
  }
  
  /// Finds and returns the value of the first element in the xml and its children whose key matches the given
  /// key.
  ///
  /// Note: We're doing something akin to a `depth first pre-order search` of a general tree here.
  /// The time complexity is `O(n)` where n is the number of nodes (children and their children and so forth).
  /// The space complexity will be `O(|m|)` where `m` is the average size of each node.
  ///
  /// Since we exist as soon as we find a node which matches the criteria, we have a `best case` where
  /// time complexity is `O(1)` and space complexity is `O(v)` where v is the size of the first node
  /// visitied.
  ///
  /// - Parameter key: Key for the item
  /// - Returns: The first value found in the xml or in one of its children whose key matches the given key.
  /// Returns nil if no element with given key is found.
  func findFirstRecursivelyInAttributes(_ key: String) -> String? {
    if let value = self.attributes[key] as? String {
      return value
    }
    
    for child in children {
      if let value = child.findFirstRecursivelyInAttributes(key) {
        return value
      }
    }
    
    return nil
  }
}
