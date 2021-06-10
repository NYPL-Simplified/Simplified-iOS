//
//  NYPLAxisTasksAggregator.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-06-08.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

protocol NYPLAxisTasksSynchorizing: class {
  func startSynchronizedTask()
  func endSynchronizedTask()
  func waitForSynchronizedTaskToFinish()
  func startSynchronizedTaskWhenIdle()
  func runOnCompletingAllSynchronizedTasks(on queue: DispatchQueue, closure: (() -> Void)?)
}

extension NYPLAxisTasksSynchorizing {
  func startSynchronizedTaskWhenIdle() {
    waitForSynchronizedTaskToFinish()
    startSynchronizedTask()
  }
}

/// Wrapper class for aggregating a set of tasks and synchronizing behavior
class NYPLAxisTasksSynchnorizer: NYPLAxisTasksSynchorizing {
  
  private let dispatchGroup: DispatchGroup
  
  init(dispatchGroup: DispatchGroup = DispatchGroup()) {
    self.dispatchGroup = dispatchGroup
  }
  
  /// Starts a new synchronized task and explicitly indicates that a block has entered the group.
  ///
  /// Call this method right before starting a synchronized task to enter the dispatchGroup.
  func startSynchronizedTask() {
    dispatchGroup.enter()
  }
  
  /// Explicitly indicates that a block in the group finished executing.
  ///
  /// Call this method right after finishing a synchronized task to leave the dispatchGroup. Calling this
  /// method decrements the current count of outstanding tasks in the group. Using this method (with
  /// startSynchronizedTask()) allows you to properly manage the task reference count.
  ///
  /// - Note: A call to this method must balance a call to `startSynchronizedTask()`. It is invalid
  /// to call it more times than startSynchronizedTask(), which would result in a negative count.
  func endSynchronizedTask() {
    dispatchGroup.leave()
  }
  
  /// Waits synchronously for the previously submitted work to finish.
  func waitForSynchronizedTaskToFinish() {
    dispatchGroup.wait()
  }
  
  /// Schedules the submission of a block to a queue when all tasks in the current group have finished
  /// executing. If the group is empty (no block objects are associated with the dispatch group), the
  /// notification block object is submitted immediately.
  ///
  /// - Parameters:
  ///   - queue: The queue to which the supplied block is submitted when the group completes.
  ///   - closure: The work to be performed on the dispatch queue when the group is completed.
  func runOnCompletingAllSynchronizedTasks(on queue: DispatchQueue,
                                           closure: (() -> Void)?) {
    dispatchGroup.notify(queue: queue) {
      closure?()
    }
  }
  
}
