//
//  DPLA.swift
//  SimplyE
//
//  Created by Vladimir Fedorov on 01.09.2020.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

/// DPLA Audiobooks DRM helper class
class DPLAAudiobooks {
  
  enum DPLAError: Error {
    case drmKeyError(_ message: String)
    
    var localisedDescription: String {
      switch self {
      case .drmKeyError(let message): return message
      }
    }
  }
  
  /// Cache-Control header
  private static let cacheControlField = "Cache-Control"
  /// max-age parameter of Cache-Control field
  private static let maxAge = "max-age"
  /// Certificate URL
  static let certificateUrl = URL(string: "https://listen.cantookaudio.com/.well-known/jwks.json")!
  
  /// Requests and returns a private key for audiobooks DRM
  /// - Parameter completion: private key data
  static func drmKey(completion: @escaping (_ keyData: Data?, _ validThrough: Date?, _ error: Error?) -> ()) {
    let task = URLSession.shared.dataTask(with: DPLAAudiobooks.certificateUrl) { (data, response, error) in
      // In case of an error
      if let error = error {
        completion(nil, nil, DPLAError.drmKeyError("Error accessing \(DPLAAudiobooks.certificateUrl): \(error)"))
        return
      }
      // If data can't be parsed, return its content in error message
      var dataString: String = ""
      if data != nil {
        dataString = String(data: data!, encoding: .utf8) ?? ""
      }
      guard let data = data,
        let response = response as? HTTPURLResponse,
        let jwkResponse = try? JSONDecoder().decode(JWKResponse.self, from: data),
        let jwk = jwkResponse.keys.first,
        let keyData = jwk.publicKeyData
        else {
          completion(nil, nil, DPLAError.drmKeyError("Error decoding \(DPLAAudiobooks.certificateUrl) response:\n\(dataString)"))
          return
        }
      // DRM is valid during a certain period of time
      // Check "Cache-Control" header for max-age value in seconds
      var validThroughDate: Date?
      if let cacheControlHeader = response.allHeaderFields[cacheControlField] as? String {
        let cacheControlComponents = cacheControlHeader.components(separatedBy: "=").map { $0.trimmingCharacters(in: .whitespaces) }
        if cacheControlComponents.count == 2 && cacheControlComponents[0].lowercased() == maxAge {
          if let seconds = Int(cacheControlComponents[1]) {
            validThroughDate = Date().addingTimeInterval(TimeInterval(seconds))
          }
        }
      }
      // All is good
      completion(keyData, validThroughDate, nil)
    }
    task.resume()
  }
}
