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

private let NYPLAudiobookProgressSavingInterval: DispatchTimeInterval = .seconds(60)

@objc extension NYPLBookCellDelegate {
  
  // Create a timer that saves the audiobook progress periodically when the app is inactive.
  // We do save the progress when app is being killed and applicationWillTerminate: is called,
  // but applicationWillTerminate: is not always called when users force quit the app.
  // This method is triggered when app resigns active.
  @objc(scheduleProgressSavingTimerForAudiobookManager:)
  func scheduleProgressSavingTimer(for manager: DefaultAudiobookManager) {
    Log.info(#function, "349 - Testing DispatchSourceTimer")
    weak var weakManager = manager
    manager.progressSavingTimer = DispatchSource.repeatingTimer(interval: NYPLAudiobookProgressSavingInterval) {
      var isActive = false
      
      NYPLMainThreadRun.sync {
        isActive = UIApplication.shared.applicationState == .active
      }

      DispatchQueue.global(qos: .background).sync {
        if isActive {
          weakManager?.progressSavingTimer = nil
        } else {
          if weakManager?.progressSavingTimer != nil {
            NYPLBookRegistry.shared().save()
          }
        }
      }
    }
  }
}
#endif
