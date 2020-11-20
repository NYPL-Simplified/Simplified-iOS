//
//  LCPLicenseInfo.swift
//  Simplified
//
//  Created by Vladimir Fedorov on 10.11.2020.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

#if LCP

import Foundation
import ReadiumLCP

/// Provides text information from `LCPAuthenticatedLicense`  for `LCPAuthenticationViewController`.
class LCPLicenseInfo {
  
  /// License info
  var license: LCPAuthenticatedLicense
  
  /// Creates a new adapter based on the provided LCP license info
  /// - Parameter license: license info
  init(license: LCPAuthenticatedLicense) {
    self.license = license
    self.supportLinks = license.supportLinks
      .compactMap { link -> (Link, URL)? in
        guard let url = URL(string: link.href), UIApplication.shared.canOpenURL(url) else {
          return nil
        }
        return (link, url)
      }
  }
  
  /// A hint to be displayed to the User to help them remember the User Passphrase.
  var hint: String {
    return license.hint
  }
  
  /// Location where a Reading System can redirect a User looking for additional information about the User Passphrase.
  var hintLink: Link? {
    return license.hintLink
  }
  
  /// Support resources for the user (either a website, an email or a telephone number).
  let supportLinks: [(Link, URL)]
  
  /// URI of the license provider.
  var provider: String {
    return license.provider
  }
  
  /// Informations about the user owning the license.
  var user: User? {
    return license.user
  }
  
}

#endif
