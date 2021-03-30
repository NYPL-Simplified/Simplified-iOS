//
//  NYPLBookmarkSpec.swift
//  Simplified
//
//  Created by Ettore Pasquini on 3/24/21.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

/// A struct that represents all the keys and some of the fixed values
/// required by the bookmark specification.
///
/// The structure of this type mimics the structure of the spec, as one
/// can see from the [provided examples](https://git.io/JYYFZ).
/// All required keys are listed. When a `value` property is present,
/// it means it's a required fixed value. E.g. the `"type"` key *MUST*
/// have a `"Annotation"` value. Fields that allow more than one
/// fixed value are expressed with enums (e.g. see `Motivation`.)
///
/// Bookmarks created inside the R2 reader *MUST* provide a value for all
/// the keys listed here; exceptions are noted on the individual field.
///
/// Bookmarks created inside the R1 reader *MAY* comply to the same spec
/// and historically some of the key/values overlap, although there has not
/// been consistence in how those bookmarks are defined, especially
/// cross-platform.
///
/// See the [full spec](https://github.com/NYPL-Simplified/Simplified-Bookmarks-Spec)
/// for more details.
struct NYPLBookmarkSpec {
  struct Context {
    static let key = "@context"
    static let value = "http://www.w3.org/ns/anno.jsonld"
  }
  struct type {
    static let key = "type"
    static let value = "Annotation"
  }
  struct Id {
    static let key = "id"
  }
  struct Body {
    static let key = "body"
    struct Time {
      static let key = "http://librarysimplified.org/terms/time"
    }
    struct Device {
      static let key = "http://librarysimplified.org/terms/device"
    }
  }
  enum Motivation: String {
    static let key = "motivation"
    static let bookmarkingKeyword = "bookmarking"
    case bookmark = "http://www.w3.org/ns/oa#bookmarking"
    case readingProgress = "http://librarysimplified.org/terms/annotation/idling"
  }
  struct Target {
    static let key = "target"
    struct Selector {
      static let key = "selector"
      struct type {
        static let key = "type"
        static let value = "oa:FragmentSelector"
      }
      struct Value {
        static let key = "value"
        static let locatorTypeKey = "@type"
        static let locatorChapterIDKey = "idref"
        static let locatorChapterProgressionKey = "progressWithinChapter"

        /// This is a key related to an optional Selector Value field,
        /// provided for backward compatibility with R1 bookmarks.
        static let locatorContentCFIKey = "contentCFI"
      }
    }
    struct Source {
      static let key = "source"
    }
  }
}
