//
//  NYPLAdobeContentProtectionService.swift
//  Simplified
//
//  Created by Ettore Pasquini on 5/11/21.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

#if FEATURE_DRM_CONNECTOR

import Foundation
import R2Shared
import R2Streamer
import R2Navigator

final class NYPLAdobeContentProtectionService: ContentProtectionService {
  var error: Error?
  let context: PublicationServiceContext

  init(context: PublicationServiceContext) {
    self.context = context
    self.error = nil
    if let adobeFetcher = context.fetcher as? AdobeDRMFetcher {
      if let drmError = adobeFetcher.container.epubDecodingError {
        self.error = NSError(domain: "Adobe DRM decoding error",
                             code: NYPLErrorCode.adobeDRMFulfillmentFail.rawValue,
                             userInfo: [
                              "AdobeDRMContainer error msg": drmError
                             ])
      }
    }
  }

  /// A restricted publication has a limited access to its manifest and
  /// resources and can’t be rendered with a Navigator. It is usually
  /// only used to import a publication to the user’s bookshelf.
  var isRestricted: Bool {
    context.publication.ref == nil || error != nil
  }

  var rights: UserRights {
    isRestricted ? AllRestrictedUserRights() : UnrestrictedUserRights()
  }

  var name: LocalizedString? {
    LocalizedString.nonlocalized("Adobe DRM")
  }

}

#endif
