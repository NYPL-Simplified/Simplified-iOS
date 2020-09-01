//
//  ASN1.swift
//  SimplyE
//
//  Created by Vladimir Fedorov on 31.08.2020.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

/**
 ASN.1 Element
 
 ASN.1 - Abstract Syntax Notation One
 DER - Distinguished Encoding Rules - defines every element as following:
 - identifier octets
 - length octets (big endian, 0x1234 will be encoded as [0x12, 0x34])
 - contents octets
 
 ASN1Element protocol encodedValue is element data encoded following DER
 
 Documentation ITU-T X.690: https://www.itu.int/rec/T-REC-X.690-201508-I/en
 */
protocol ASN1Element {
  /// Type of the element
  var tag: ASN1.Tag { get }
  /// Contents of the element
  var data: Data { get }
  /// Encoded length octets
  var encodedLength: Data { get }
  /// Element value, encoded following DER
  var encodedValue: Data { get }
}


extension ASN1Element {
  /*
   The definite form of the length octets
   In the short form, the length octets shall consist of a single octet
   in which bit 8 is zero and bits 7 to 1 encode the number of octets in the contents octets
   In the long form, the length octets shall consist of an initial octet and one or more subsequent octets:
   - bit 8 shall be one;
   - bits 7 to 1 shall encode the number of subsequent octets in the length octets, as an unsigned binary integer with bit 7 as the most significant bit;
   - the value 11111111b shall not be used.
   */
  var encodedLength: Data {
    let length = data.count
    var lengthOctets: [UInt8] = []
    if length <= 127 {
      // Short form
      lengthOctets.append(UInt8(length))
    } else {
      // Long form
      var lengthValue = length.bigEndian
      // Actual number of non-zero bytes to encode length value (1...8)
      let lengthData = Data(bytes: &lengthValue, count: MemoryLayout.size(ofValue: lengthValue))
      var lengthBytes = Array(lengthData)
      if let index = lengthBytes.firstIndex(where: { $0 > 0 }), index > 0 {
        lengthBytes.removeFirst(index)
      }
      // number of bytes the length takes with bit 8 set to 1
      // there's no check for 0x7f value because number of bytes in the length value will always be smaller,
      // 4 in 32-bit and 8 in 64-bit systems
      lengthOctets.append(UInt8(0x80) | UInt8(lengthBytes.count))
      // length bytes, big endian order
      lengthOctets.append(contentsOf: lengthBytes)
    }
    return Data(lengthOctets)
  }
  /*
   identifier | length | contents
   */
  var encodedValue: Data {
    tag.data + encodedLength + data
  }
}

/**
 ASN1 is a partial implementation of ASN.1 DER
 
 ASN.1 - Abstract Syntax Notation One
 
 DER - Distinguished Encoding Rules
 
 This class implements `SEQUENCE` and `INTEGER` elements of the encoding rules as described in ITU-T X.690.
 */
class ASN1 {
  /// ASN.1 Tags
  enum Tag: UInt8 {
    case integer = 0x02
    case sequence = 0x30
    
    /// Data representation of tag value
    var data: Data {
      Data([self.rawValue])
    }
  }
  /// ASN.1 Sequence element
  class Sequence: ASN1Element {
    let tag = Tag.sequence
    var elements: [ASN1Element] = []
    var data: Data {
      var encodedElements = Data()
      elements.forEach {
        encodedElements.append($0.encodedValue)
      }
      return encodedElements
    }
    /// Adds the new element to sequence elements and returns this sequence
    /// - Parameter element: `ASN1Element`
    /// - Returns: `self` appending the new element
    func appending(_ element: ASN1Element) -> Self {
      elements.append(element)
      return self
    }
    /// Adds the new element to sequence elements
    /// - Parameter element: `ASN1Element`
    func append(_ element: ASN1Element) {
      elements.append(element)
    }
  }
  /// ASN.1 Integer element
  class Integer: ASN1Element {
    let tag = Tag.integer
    /// Internal representation of an object
    var data: Data
    /// ASN.1 Integer
    /// - Parameter data: Integer data value
    init(data: Data) {
      var bytes = Array(data)
      // Bit 8 of the first byte should not be 1
      // according to 8.3.3 of X.690
      if bytes[0] > 127 {
        bytes = [0] + bytes
      }
      self.data = Data(bytes)
    }
  }
}
