//
//  NYPLBookCellDelegate+AudiobookBookmark.swift
//  Simplified
//
//  Created by Ernest Fan on 2022-10-21.
//  Copyright © 2022 NYPL. All rights reserved.
//

#if FEATURE_AUDIOBOOKS
import Foundation
import NYPLAudiobookToolkit
import UIKit

/// The NYPLAudiobookBookmarksBusinessLogic is not accessible from ObjC,
/// so we do this in a Swift extension file.
@objc extension NYPLBookCellDelegate {
  @objc(setBookmarkBusinessLogicForBook:AudiobookManager:AudiobookRegistryProvider:)
  func setBookmarkBusinessLogic(for book: NYPLBook,
                                audiobookManager: DefaultAudiobookManager,
                                audiobookRegistryProvider: NYPLAudiobookRegistryProvider) {
    let bizLogic = NYPLAudiobookBookmarksBusinessLogic(
      book: book,
      drmDeviceID: NYPLUserAccount.sharedAccount().deviceID,
      bookRegistryProvider: audiobookRegistryProvider,
      serverPermissions: AccountsManager.shared,
      annotationsSynchronizer: NYPLAnnotations.self)
    audiobookManager.bookmarkBusinessLogic = bizLogic
  }
}
#endif
