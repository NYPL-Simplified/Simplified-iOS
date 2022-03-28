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

private let NYPLAudiobookProgressSavingInterval: DispatchTimeInterval = .seconds(60)

@objc extension NYPLBookCellDelegate {
  
  private func savePosition() {
    NYPLBookRegistry.shared().save()
  }
  
  // Create a timer that saves the audiobook progress periodically when the app is inactive.
  // We do save the progress when app is being killed and applicationWillTerminate: is called,
  // but applicationWillTerminate: is not always called when users force quit the app.
  // This method is triggered when app resigns active.
  @objc(scheduleProgressSavingTimerForAudiobookManager:)
  func scheduleProgressSavingTimer(for manager: DefaultAudiobookManager?) {
    guard let manager = manager else {
      return
    }

    weak var weakManager = manager
    
    let timer = NYPLRepeatingTimer(interval: NYPLAudiobookProgressSavingInterval,
                                   queue: self.audiobookProgressSavingQueue) { [weak self] in
      var isActive = false

      NYPLMainThreadRun.sync {
        isActive = UIApplication.shared.applicationState == .active
      }

      if isActive {
        // DispatchSourceTimer will automatically cancel the timer if it is released.
        weakManager?.cancelProgressSavingTimer()
      } else {
        if let manager = weakManager,
           !manager.progressSavingTimerIsNil() {
          self?.savePosition()
        }
      }
    }
    manager.setProgressSavingTimer(timer)
  }
}
#endif
