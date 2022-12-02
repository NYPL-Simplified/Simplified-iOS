//
//  NYPLBookCellDelegate+AudiobookProgressSaving.swift
//  Simplified
//
//  Created by Ernest Fan on 2022-03-01.
//  Copyright © 2022 NYPL. All rights reserved.
//
#if FEATURE_AUDIOBOOKS
import Foundation
import NYPLAudiobookToolkit
import UIKit
import NYPLUtilities

private let NYPLAudiobookPositionSyncingInterval: DispatchTimeInterval = .seconds(60)

@objc extension NYPLBookCellDelegate {
  
  private func savePosition() {
    NYPLBookRegistry.shared().save()
  }
  
  // Create a timer that saves the audiobook progress to disk and post to server periodically.
  // We do save the progress when app is being killed and applicationWillTerminate: is called,
  // but applicationWillTerminate: is not always called when users force quit the app.
  // We only save to disk when app is in background.
  @objc(scheduleLastListenPositionSynchronizingTimerForAudiobookManager:)
  func scheduleLastListenPositionSynchronizingTimer(for manager: DefaultAudiobookManager?) {
    guard let manager = manager else {
      return
    }

    weak var weakManager = manager
    
    let timer = NYPLRepeatingTimer(interval: NYPLAudiobookPositionSyncingInterval,
                                   queue: self.audiobookProgressSavingQueue) { [weak self] in
      var isActive = false

      NYPLMainThreadRun.sync {
        isActive = UIApplication.shared.applicationState == .active
      }

      // Save audiobook progress to disk if app is in background
      if !isActive {
        self?.savePosition()
      }
      
      // Post audiobook progress to server
      if let manager = weakManager {
        manager.lastListenPositionSynchronizer?.syncLastListenPositionToServer()
      }
    }
    manager.setLastListenPositionSyncingTimer(timer)
  }
  
  @objc(setLastListenPositionSynchronizerForBook:AudiobookManager:BookRegistryProvider:)
  func setLastListenPositionSynchronizer(for book: NYPLBook,
                                         audiobookManager: DefaultAudiobookManager,
                                         bookRegistryProvider: NYPLBookRegistryProvider) {
    let lastListenPosSynchronizer = NYPLLastListenPositionSynchronizer(book: book,
                                                                       bookRegistryProvider: bookRegistryProvider,
                                                                       annotationsSynchronizer: NYPLRootTabBarController.shared().annotationsSynchronizer)
    
    audiobookManager.lastListenPositionSynchronizer = lastListenPosSynchronizer
  }
}
#endif
