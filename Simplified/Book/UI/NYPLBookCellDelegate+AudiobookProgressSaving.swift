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
    manager.progressSavingTimer = DispatchSource.repeatingTimer(interval: NYPLAudiobookProgressSavingInterval) {
      var isActive = false

      NYPLMainThreadRun.asyncIfNeeded {
        isActive = UIApplication.shared.applicationState == .active
      }

      DispatchQueue.global(qos: .background).async { [weak self] in
        if isActive {
          weakManager?.progressSavingTimer?.suspend()
          weakManager?.progressSavingTimer = nil
        } else {
          if weakManager?.progressSavingTimer != nil {
            self?.savePosition()
          }
        }
      }
    }
  }
}
#endif
