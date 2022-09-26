//
//  NYPLBookRegistry+Audiobook.swift
//  Simplified
//
//  Created by Ernest Fan on 2022-09-09.
//  Copyright © 2022 NYPL. All rights reserved.
//
#if FEATURE_AUDIOBOOKS
import Foundation
import NYPLAudiobookToolkit

@objc protocol NYPLAudiobookRegistryProvider {
  @objc(audiobookBookmarksForIdentifier:)
  func audiobookBookmarks(for identifier: String) -> [NYPLAudiobookBookmark]
  
  @objc(addAudiobookBookmark:forIdentifier:)
  func addAudiobookBookmark(_ audiobookBookmark: NYPLAudiobookBookmark, for identifier: String)
  
  @objc(deleteAudiobookBookmark:forIdentifier:)
  func deleteAudiobookBookmark(_ audiobookBookmark: NYPLAudiobookBookmark, for identifier: String)
  
  @objc(replaceAudiobookBookmark:withNewAudiobookBookmark:forIdentifier:)
  func replaceAudiobookBookmark(_ oldAudiobookBookmark: NYPLAudiobookBookmark,
                                with newAudiobookBookmark: NYPLAudiobookBookmark,
                                for identifier: String)
}
#endif
