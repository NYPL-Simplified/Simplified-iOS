//
//  R2+NYPLAdditions.swift
//  Simplified
//
//  Created by Ettore Pasquini on 6/11/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation
import R2Shared

extension Publication {

  /// Obtain a R2 Link object from a given id reference. This for example
  /// can be used to get the link object related to a R1 bookmark by
  /// passing in the NYPLReadiumBookmark::idref.
  /// - Parameter idref: The ID for the given position in the publication.
  /// - Returns: The Link object matching the given ID, if it exists in the
  /// publication.
  func link(withIDref idref: String) -> Link? {
    // The Publication stores all positions from the Epub in various
    // collections of Link objects. For bookmarks, these are contained inside
    // the `readingOrder` list. Each Link stores its metadata in a `properties`
    // dictionary.
    return link { $0.properties["id"] as? String == idref }
  }

  /// Shortcut helper to get the publication ID.
  var id: String? {
    return metadata.identifier
  }
}
