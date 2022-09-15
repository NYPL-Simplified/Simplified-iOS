//
//  NYPLBookmarkFactory.swift
//  Simplified
//
//  Created by Ernest Fan on 2022-09-13.
//  Copyright © 2022 NYPL. All rights reserved.
//

import Foundation
import R2Shared
import NYPLUtilities
import NYPLAudiobookToolkit

class NYPLBookmarkFactory: NYPLBookmarkSelectorParsing {
  /// Factory method to parse selector JSON value from a server annotation.
  ///
  /// - Parameters:
  ///   - annotation: The annotation object coming from the server in a
  ///   JSON-like structure.
  ///   - annotationType: Whether it's an explicit bookmark or a reading progress.
  ///   - bookID: The book the annotation is related to.
  ///   missing from the annotation, e.g. if the annotation was created on an
  ///   R1 client.
  /// - Returns: a client-side representation of a bookmark.
  class func parseSelectorJSONString(fromServerAnnotation annotation: [String: Any],
                                     annotationType: NYPLBookmarkSpec.Motivation,
                                     bookID: String) -> String? {
    guard
      let target = annotation[NYPLBookmarkSpec.Target.key] as? [String: Any],
      let source = target[NYPLBookmarkSpec.Target.Source.key] as? String,
      let motivation = annotation[NYPLBookmarkSpec.Motivation.key] as? String
    else {
      Log.error(#file, "Error parsing required info (target, source, motivation, body) for bookID \(bookID) in annotation: \(annotation)")
      return nil
    }

    guard source == bookID else {
      NYPLErrorLogger.logError(withCode: .bookmarkReadError,
                               summary: "Got bookmark for a different book",
                               metadata: [
                                "requestedBookID": bookID,
                                "serverAnnotation": annotation])
      return nil
    }

    guard motivation.contains(annotationType.rawValue) else {
      Log.error(#file, "Can't create bookmark for bookID \(bookID), `\(motivation)` motivation does not match expected `\(annotationType.rawValue)` motivation.")
      return nil
    }

    guard
      let selector = target[NYPLBookmarkSpec.Target.Selector.key] as? [String: Any],
      let selectorValueEscJSON = selector[NYPLBookmarkSpec.Target.Selector.Value.key] as? String
      else {
        Log.error(#file, "Error reading required Selector Value for bookID \(bookID) from Target: \(target)")
        return nil
    }
    
    return selectorValueEscJSON
  }
}
