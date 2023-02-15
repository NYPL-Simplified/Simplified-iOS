//
//  NYPLBookCellDelegate+AudiobookLastListenPositio.swift
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

      NYPLMainThreadRun.asyncIfNeeded {
        isActive = UIApplication.shared.applicationState == .active
        
        // Save audiobook progress to disk if app is in background
        if !isActive {
          self?.savePosition()
        }
      }
      
      // Post audiobook progress to server
      if let manager = weakManager {
        manager.lastListenPositionSynchronizer?.syncLastListenPositionToServer()
      }
    }
    manager.setLastListenPositionSyncingTimer(timer)
  }
  
  /// - Important: Must be called on the main thread since it accesses NYPLRootTabBarController.
  @objc(setLastListenPositionSynchronizerForBook:audiobookManager:bookRegistryProvider:deviceID:)
  func setLastListenPositionSynchronizer(for book: NYPLBook,
                                         audiobookManager: DefaultAudiobookManager,
                                         bookRegistryProvider: NYPLBookRegistryProvider,
                                         deviceID: String?) {
    let lastListenPosSynchronizer = NYPLLastListenPositionSynchronizer(book: book,
                                                                       bookRegistryProvider: bookRegistryProvider,
                                                                       annotationsSynchronizer: NYPLRootTabBarController.shared().annotationsSynchronizer,
                                                                       deviceID: deviceID)
    
    audiobookManager.lastListenPositionSynchronizer = lastListenPosSynchronizer
  }
  
  @objc(restoreLastListenPositionAndPresentAudiobookPlayerVC:audiobookManager:successCompletion:)
  func restoreLastListenPositionAndPresent(audiobookPlayerVC: AudiobookPlayerViewController,
                                           audiobookManager: DefaultAudiobookManager,
                                           successCompletion: (() -> ())?) {
    // Restore last listen position from local storage and server
    audiobookManager.lastListenPositionSynchronizer?.getLastListenPosition(completion: { [weak self] localPosition, serverPosition in
      
      guard let self = self else {
        return
      }
      
      NYPLMainThreadRun.asyncIfNeeded {
        // Present audio player
        NYPLRootTabBarController.shared().pushViewController(audiobookPlayerVC, animated: true)
        // Call completion handler when audiobook has been successfully opened
        successCompletion?()
        
        // Present alert for user to decide if they want to move to position found on server
        if let serverPosition = serverPosition {
          self.presentAlert(serverPosition) { position in
            let finalPosition = position != nil ? position : localPosition
            guard let finalPosition = finalPosition else {
              return
            }
            
            audiobookManager.movePlayhead(to: finalPosition)
          }
        } else if let localPosition = localPosition {
          audiobookManager.movePlayhead(to: localPosition)
        }
      }
    })
  }
  
  private func presentAlert(_ serverPosition: NYPLAudiobookBookmark,
                            completion: @escaping (NYPLAudiobookBookmark?) -> ()) {
    let alert = UIAlertController(title: NSLocalizedString("Sync Reading Position",
                                                           comment: "An alert title notifying the user the listening position has been synced"),
                                  message: NSLocalizedString("Do you want to stay at this location in your audiobook or move to the furthest location you have listened to?",
                                                             comment: "An alert message asking the user to perform navigation to the synced listening position or not"),
                                  preferredStyle: .alert)

    let stayText = NSLocalizedString("Stay", comment: "Do not perform navigation")
    let stayAction = UIAlertAction(title: stayText, style: .cancel) { _ in
      completion(nil)
    }

    let moveText = NSLocalizedString("Move", comment: "Perform navigation")
    let moveAction = UIAlertAction(title: moveText, style: .default) { _ in
      completion(serverPosition)
    }

    alert.addAction(stayAction)
    alert.addAction(moveAction)

    NYPLPresentationUtils.safelyPresent(alert)
  }
}
#endif
