//
//  NYPLBookRegistry+Audiobook.swift
//  Simplified
//
//  Created by Ernest Fan on 2022-09-09.
//  Copyright © 2022 NYPL. All rights reserved.
//

import Foundation
import NYPLAudiobookToolkit

#if FEATURE_AUDIOBOOKS
protocol NYPLAudiobookRegistryProvider {
  func audiobookBookmarks(for identifier: String) -> [NYPLAudiobookBookmark]
  func addAudiobookBookmark(_ audiobookBookmark: NYPLAudiobookBookmark, for identifier: String)
  func deleteAudiobookBookmark(_ audiobookBookmark: NYPLAudiobookBookmark, for identifier: String)
  func replaceAudiobookBookmark(_ oldAudiobookBookmark: NYPLAudiobookBookmark,
                                with newAudiobookBookmark: NYPLAudiobookBookmark,
                                for identifier: String)
}

extension NYPLBookRegistry: NYPLAudiobookRegistryProvider {
  func audiobookBookmarks(for identifier: String) -> [NYPLAudiobookBookmark] {
    
    return []
  }
  
  func addAudiobookBookmark(_ audiobookBookmark: NYPLAudiobookBookmark, for identifier: String) {
    
  }
  
  func deleteAudiobookBookmark(_ audiobookBookmark: NYPLAudiobookBookmark, for identifier: String) {
    
  }
  
  func replaceAudiobookBookmark(_ oldAudiobookBookmark: NYPLAudiobookBookmark,
                                with newAudiobookBookmark: NYPLAudiobookBookmark,
                                for identifier: String) {
    
  }
}
#endif
