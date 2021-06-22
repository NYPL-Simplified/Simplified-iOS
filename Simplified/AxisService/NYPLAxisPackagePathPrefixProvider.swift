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

struct NYPLAxisPackagePathPrefixProvider: NYPLAxisPackagePathPrefixProviding {
  
  /// Generates and returns path prefix for downloadable content from the package endpoint extracted from
  /// the package.opf file.
  ///
  /// - Parameter packageEndpoint: Package endpoint
  /// - Returns: Generated path prefix (optional)
  func getPackagePathPrefix(packageEndpoint: String?) -> String? {
    guard let packageEndpoint = packageEndpoint else {
      // No need to log error here since an error is already logged when
      // pacakgeEndpoint generation returns nil
      return nil
    }
    
    let packagePathPrefix = URL(string: packageEndpoint)?
      .deletingLastPathComponent()
      .absoluteString
    
    /// For most books, package content lives inside a directory e.g. abc/def/package.opf and we use the
    /// parent directory of the opf file as package endpoint. However, for some books, the package content
    /// is in root directory. In that case, we do not need to provide a package prefix.
    if packagePathPrefix == "./" {
      return nil
    }
    
    return packagePathPrefix
  }
  
}

#endif
