//
//  NYPLAnnotations+Deprecated.swift
//  Simplified
//
//  Created by Ettore Pasquini on 3/24/21.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

/// - Important: all these functions are deprecated. Do not use in new code.
extension NYPLAnnotations {
  /// - Important: this is deprecated. Do not use in new code.
  class func postR1Bookmark(_ bookmark: NYPLReadiumBookmark,
                            forBookID bookID: String,
                            completion: @escaping (_ serverID: String?) -> ())
  {
    guard syncIsPossibleAndPermitted() else {
      Log.debug(#file, "Account does not support sync or sync is disabled.")
      completion(nil)
      return
    }

    guard let annotationsURL = NYPLAnnotations.annotationsURL else {
      Log.error(#file, "Annotations URL was nil while posting R1 bookmark")
      return
    }

    let parameters = [
      NYPLBookmarkSpec.Context.key: NYPLBookmarkSpec.Context.value,
      NYPLBookmarkSpec.type.key: NYPLBookmarkSpec.type.value,
      NYPLBookmarkSpec.Motivation.key: NYPLBookmarkSpec.Motivation.bookmark.rawValue,
      NYPLBookmarkSpec.Target.key: [
        NYPLBookmarkSpec.Target.Source.key: bookID,
        NYPLBookmarkSpec.Target.Selector.key: [
          NYPLBookmarkSpec.Target.Selector.type.key: NYPLBookmarkSpec.Target.Selector.type.value,
          NYPLBookmarkSpec.Target.Selector.Value.key: bookmark.location
        ]
      ],
      NYPLBookmarkSpec.Body.key: [
        NYPLBookmarkSpec.Body.Time.key : bookmark.time,
        NYPLBookmarkSpec.Body.Device.key : bookmark.device ?? "",
        "http://librarysimplified.org/terms/chapter" : bookmark.chapter ?? "",
        "http://librarysimplified.org/terms/progressWithinChapter" : bookmark.progressWithinChapter,
        "http://librarysimplified.org/terms/progressWithinBook" : bookmark.progressWithinBook,
      ]
      ] as [String : Any]

    postAnnotation(forBook: bookID, withAnnotationURL: annotationsURL, withParameters: parameters, queueOffline: false) { (success, id) in
      completion(id)
    }
  }
}
