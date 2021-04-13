//
//  Publication+NYPLAdditions.swift
//  Simplified
//
//  Created by Ettore Pasquini on 6/11/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation
import R2Shared

extension Publication {
  static let idrefKey = "id"

  /// Obtains a R2 Link object from a given ID reference.
  ///
  /// This for example can be used to get the link object related to a R1
  /// bookmark by passing in the NYPLReadiumBookmark::idref.
  ///
  /// - Complexity: O(*n*), where *n* is the length of `readingOrder`
  /// data structure internal to this Publication.
  ///
  /// - Parameter idref: The ID for the given chapter in the publication.
  ///
  /// - Returns: The Link object matching the given ID, if it exists in the
  /// publication.
  func link(withIDref idref: String) -> Link? {
    // The Publication stores all bookmarks (and TOC; positions in general) in
    // the `readingOrder` list of Links. Each `Link` stores its metadata in a
    // `properties` dictionary.
    return readingOrder.first { $0.properties[Publication.idrefKey] as? String == idref }
  }

  /// Obtains a R2 HREF from a given ID reference.
  ///
  /// - Complexity: O(*n*), where *n* is the length of `readingOrder`
  /// data structure internal to this Publication.
  ///
  /// - Parameter idref: The ID for the given chapter in the publication.
  ///
  /// - Returns: The HREF matching the given ID, if it exists in the
  /// publication.
  func href(forIdref idref: String?) -> String? {
    guard let idref = idref else {
      return nil
    }

    return link(withIDref: idref)?.href
  }

  /// Derives the `idref` (often used in Readium 1) from a Readium 2 `href`.
  ///
  /// You can use this function anytime you're in possession of a R2
  /// resource URI (for example from a `Link` or a `Locator` object) and
  /// need to obtain the ID of the related resource.
  ///
  /// - Complexity: O(*n*), where *n* is the length of `readingOrder`
  /// data structure internal to this Publication.
  ///
  /// - Parameter href: The URI of a resource in R2.
  ///
  /// - Returns: The `idref` related to the resource in question. This *must*
  /// be usable in R1 contexts.
  func idref(forHref href: String) -> String? {
    let link = self.link(withHREF: href)
    return link?.properties[Publication.idrefKey] as? String
  }

  /// Shortcut helper to get the publication ID.
  var id: String? {
    return metadata.identifier
  }

  /// Shortcut to get the resource index (stored within internal R2 data
  /// structures) pointed at by the given Locator.
  /// - parameter locator: The location for which we want the resource index of.
  func resourceIndex(forLocator locator: Locator) -> Int? {
    return readingOrder.firstIndex(withHREF: locator.href)
  }
}
