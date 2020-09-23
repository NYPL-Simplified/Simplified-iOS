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

  /// Obtains a R2 Link object from a given ID reference.
  ///
  /// This for example can be used to get the link object related to a R1
  /// bookmark by passing in the NYPLReadiumBookmark::idref.
  ///
  /// - Complexity: O(*n*), where *n* is the length of data structures
  /// internal to this Publication, such as resources, links, readingOrder.
  ///
  /// - Parameter idref: The ID for the given position in the publication.
  ///
  /// - Returns: The Link object matching the given ID, if it exists in the
  /// publication.
  func link(withIDref idref: String) -> Link? {
    // The Publication stores all positions from the Epub in various
    // collections of Link objects. For bookmarks, these are contained inside
    // the `readingOrder` list. Each `Link` stores its metadata in a
    // `properties` dictionary.
    return link { $0.properties["id"] as? String == idref }
  }

  /// Derives the `idref` (often used in Readium 1) from a Readium 2 `href`.
  ///
  /// You can use this function anytime you're in possession of a R2
  /// resource URI (for example from a `Link` or a `Locator` object) and
  /// need to obtain the ID of the related resource.
  ///
  /// - Complexity: O(*n*), where *n* is the length of data structures
  /// internal to this Publication, such as resources, links, readingOrder.
  ///
  /// - Parameter href: The URI of a resource in R2.
  ///
  /// - Returns: The `idref` related to the resource in question. This *should*
  /// be usable in R1 contexts.
  func idref(forHref href: String) -> String? {
    let link = self.link(withHref: href)
    return link?.properties["id"] as? String
  }

  /// Shortcut helper to get the publication ID.
  var id: String? {
    return metadata.identifier
  }

  /// Shortcut to get the resource index (stored within internal R2 data
  /// structures) pointed at by the given Locator.
  /// - parameter locator: The location for which we want the resource index of.
  func resourceIndex(forLocator locator: Locator) -> Int? {
    return readingOrder.firstIndex(withHref: locator.href)
  }
}
