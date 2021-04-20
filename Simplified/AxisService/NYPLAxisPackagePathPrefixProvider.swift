//
//  NYPLAxisPackagePathPrefixProvider.swift
//  Simplified
//
//  Created by Raman Singh on 2021-04-21.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

#if AXIS

protocol NYPLAxisPackagePathPrefixProviding {
  func getPackagePathPrefix(packageEndpoint: String?) -> String?
}

class NYPLAxisPackagePathPrefixProvider: NYPLAxisPackagePathPrefixProviding {
  
  private var packagePathPrefix: String?
  
  /// Generates, stores, and returns path prefix for downloadable content from the package endpoint
  /// extracted from the package.opf file. Returns stored value on subsequent calls.
  /// - Parameter packageEndpoint: Package endpoint
  /// - Returns: Generated or stored (if already generated in a previous call) path prefix (optional)
  func getPackagePathPrefix(packageEndpoint: String?) -> String? {
    if let pathPrefix = packagePathPrefix {
      return pathPrefix
    }
    
    guard let packageEndpoint = packageEndpoint else {
      // No need to log error here since an error is already logged when
      // pacakgeEndpoint generation returns nil
      return nil
    }
    
    packagePathPrefix = URL(string: packageEndpoint)?
      .deletingLastPathComponent()
      .absoluteString
    
    return packagePathPrefix
  }
  
}

#endif
