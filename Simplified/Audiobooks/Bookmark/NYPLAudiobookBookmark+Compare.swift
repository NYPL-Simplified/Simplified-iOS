//
//  NYPLAudiobookBookmark+Compare.swift
//  Simplified
//
//  Created by Ernest Fan on 2022-09-16.
//  Copyright © 2022 NYPL. All rights reserved.
//
#if FEATURE_AUDIOBOOKS
import Foundation
import NYPLAudiobookToolkit

// These functions/extensions need to live in the Simplified-iOS repo because
// the =~= operator is defined here
extension NYPLAudiobookBookmark {
  /// Determines if a given chapter location matches the location addressed by this
  /// bookmark.
  ///
  /// - Complexity: O(*1*).
  ///
  /// - Parameters:
  ///   - locator: The object representing the given location in the audiobook
  ///
  /// - Returns: `true` if the chapter location's position matches the bookmark's.
  func locationMatches(_ location: ChapterLocation) -> Bool {
    guard self.audiobookId == location.audiobookID,
          self.chapter == location.number,
          self.part == location.part,
          self.duration == location.duration else {
      return false
    }
    
    return Float(self.time) =~= Float(location.playheadOffset)
  }
  
  override public func isEqual(_ object: Any?) -> Bool {
    guard let other = object as? NYPLAudiobookBookmark else {
      return false
    }

    guard self.audiobookId == other.audiobookId,
          self.chapter == other.chapter,
          self.part == other.part else {
      return false
    }
    
    return Float(self.time) =~= Float(other.time)
  }
}

extension NYPLAudiobookBookmark: Comparable {
  public static func < (lhs: NYPLAudiobookBookmark, rhs: NYPLAudiobookBookmark) -> Bool {
    if lhs.part != rhs.part {
      return lhs.part < rhs.part
    } else if lhs.chapter != rhs.chapter {
      return lhs.chapter < rhs.chapter
    } else {
      return lhs.time < rhs.time
    }
  }
  
  public static func == (lhs: NYPLAudiobookBookmark, rhs: NYPLAudiobookBookmark) -> Bool {
    guard lhs.audiobookId == rhs.audiobookId,
          lhs.chapter == rhs.chapter,
          lhs.part == rhs.part else {
      return false
    }
    
    return Float(lhs.time) =~= Float(rhs.time)
  }
}

@objc extension NYPLAudiobookBookmark {
  @objc public func lessThan(_ bookmark: NYPLAudiobookBookmark) -> Bool {
    return self < bookmark
  }
}
#endif
