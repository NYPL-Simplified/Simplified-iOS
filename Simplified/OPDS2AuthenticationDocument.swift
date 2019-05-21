//
//  OPDS2AuthenticationDocument.swift
//  SimplyE
//
//  Created by Benjamin Anderman on 5/10/19.
//  Copyright © 2019 NYPL Labs. All rights reserved.
//

import Foundation

struct OPDS2AuthenticationDocument: Codable {
  struct PublicKey: Codable {
    let type: String
    let value: String
  }
  
  struct ColorScheme: Codable {
    let foreground: String
    let background: String
  }
  
  struct Features: Codable {
    let disabled: [String]?
    let enabled: [String]?
  }
  
  struct Authentication: Codable {
    struct Inputs: Codable {
      struct Input: Codable {
        let barcodeFormat: String?
        let maximumLength: UInt?
        let keyboard: String // TODO: Use enum instead (or not; it could break if new values are added)
      }
      
      let login: Input
      let password: Input
    }
    
    struct Labels: Codable {
      let login: String
      let password: String
    }
    
    let inputs: Inputs
    let labels: Labels
    let type: String
    let description: String
  }
  
  let publicKey: PublicKey
  let webColorScheme: ColorScheme?
  let features: Features
  let links: [OPDS2Link]
  let title: String
  let authentication: [Authentication]
  let serviceDescription: String?
  let colorScheme: String?
  let id: String
  
  static func fromData(_ data: Data) throws -> OPDS2AuthenticationDocument {
    let jsonDecoder = JSONDecoder()
    jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
    
    return try jsonDecoder.decode(OPDS2AuthenticationDocument.self, from: data)
  }
}
