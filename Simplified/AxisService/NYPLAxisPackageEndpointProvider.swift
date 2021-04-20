//
//  NYPLPackageEndpointProvider.swift
//  Simplified
//
//  Created by Raman Singh on 2021-04-21.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

#if AXIS

protocol NYPLAxisPackageEndpointProviding {
  func getPackageEndpoint() -> String?
}

class NYPLAxisPackageEndpointProvider: NYPLAxisPackageEndpointProviding {
  
  private let containerURL: URL
  private let fullPathKey: String
  private var packageEndpoint: String?
  
  // MARK: - Static Constants
  static private let summary = "AXIS: Failed to generate package endpoint"
  
  
  /// Creates an instance of NYPLAxisPackageEndpointProvider for extracting the endpoint for package.opf
  /// file from the Container.xml file using the given key.
  /// - Parameters:
  ///   - containerURL: URL for Container.xml file
  ///   - fullPathKey: Name of the key
  init(containerURL: URL, fullPathKey: String) {
    self.containerURL = containerURL
    self.fullPathKey = fullPathKey
  }
  
  /// Generates, stores, and returns package endpoint from the container.xml file. Returns stored value on
  /// subsequent calls.
  /// - Returns: Generated or stored (if already generated on previous call) package endpoint (optional).
  func getPackageEndpoint() -> String? {
    if let endpoint = packageEndpoint {
      return endpoint
    }
    
    let data = try? Data(contentsOf: containerURL)
    guard let axisXML = NYPLAxisXML(data: data) else {
      NYPLErrorLogger.logError(
        withCode: .axisDRMFulfillmentFail,
        summary: NYPLAxisPackageEndpointProvider.summary,
        metadata: [
          NYPLAxisService.reason: NYPLAxisXML.NYPLXMLGenerationFailure
      ])
      
      return nil
    }
    
    packageEndpoint = axisXML.findFirstRecursivelyInAttributes(fullPathKey)
    
    if (packageEndpoint == nil) {
      NYPLErrorLogger.logError(
        withCode: .axisDRMFulfillmentFail,
        summary: NYPLAxisPackageEndpointProvider.summary,
        metadata: [
          NYPLAxisService.reason: "Failed to find element with key \(fullPathKey)"
      ])
    }
    
    return packageEndpoint
  }
  
}

#endif
