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
    case requestError(_ url: URL, _ error: Error)
    case drmKeyError(_ message: String)
    
    var localisedDescription: String {
      switch self {
      case .requestError(let url, let error): return "Error requesting key data from \(url): \(error.localizedDescription)"
      case .drmKeyError(let message): return message
      }
    }
    
    var readableError: String {
      switch self {
      case .requestError: return "Error receiving DRM key."
      case .drmKeyError: return "Error decoding DRM key data."
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
  /// - Parameter keyData: Public RSA key data
  /// - Parameter validThrough: The last date the key is valid
  /// - Parameter error: Error object
  ///
  /// `completion` either returns `keyData` value or an `error`.  `validThrough` date is optional even when `keyData` is not nil.
  static func drmKey(completion: @escaping (_ keyData: Data?, _ validThrough: Date?, _ error: Error?) -> ()) {
    let task = URLSession.shared.dataTask(with: DPLAAudiobooks.certificateUrl) { (data, response, error) in
      // In case of an error
      if let error = error {
        completion(nil, nil, DPLAError.requestError(DPLAAudiobooks.certificateUrl, error))
        return
      }
      // DRM is valid during a certain period of time
      // Check "Cache-Control" header for max-age value in seconds
      var validThroughDate: Date?
      if let response = response as? HTTPURLResponse,  let cacheControlHeader = response.allHeaderFields[cacheControlField] as? String {
        let cacheControlComponents = cacheControlHeader.components(separatedBy: "=").map { $0.trimmingCharacters(in: .whitespaces) }
        if cacheControlComponents.count == 2 && cacheControlComponents[0].lowercased() == maxAge {
          if let seconds = Int(cacheControlComponents[1]) {
            validThroughDate = Date().addingTimeInterval(TimeInterval(seconds))
          }
        }
      }
      // Decode JWK data
      guard let jwkData = data else {
        completion(nil, nil, DPLAError.drmKeyError("Error decoding \(DPLAAudiobooks.certificateUrl): response data is empty"))
        return
      }
      guard let jwkResponse = try? JSONDecoder().decode(JWKResponse.self, from: jwkData),
        let jwk = jwkResponse.keys.first,
        let keyData = jwk.publicKeyData
        else {
          // If data can't be parsed or the key is missing, return its content in error message
          let dataString: String = String(data: jwkData, encoding: .utf8) ?? ""
          completion(nil, nil, DPLAError.drmKeyError("Error decoding \(DPLAAudiobooks.certificateUrl) response:\n\(dataString)"))
          return
        }
      // All is good
      completion(keyData, validThroughDate, nil)
    }
    task.resume()
  }
}
