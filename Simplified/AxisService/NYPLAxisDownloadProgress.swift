//
//  NYPLAxisDownloadProgress.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-05-27.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//
import Foundation

protocol NYPLAxisDownloadProgressHandling: class {
  var currentProgress: Double { get }
  var progressListener: NYPLAxisDownloadProgressListening? { get set }
  func addFixedWeightTask(with url: URL, weight incomingWeight: Double)
  func addFlexibleWeightTask(with url: URL)
  func didFinishTask(with url: URL)
}

class NYPLAxisDownloadProgress: NYPLAxisDownloadProgressHandling {
  
  private let allTasks: ThreadSafeValueContainer<[DownloadTask]>
  private let currentDownloadProgress: ThreadSafeValueContainer<Double>
  weak var progressListener: NYPLAxisDownloadProgressListening?
  
  var currentProgress: Double {
    return currentDownloadProgress.value ?? 0.0
  }
  
  init(queue: DispatchQueue = DispatchQueue(label: "NYPLAxisDownloadProgressQueue")) {
    self.allTasks = ThreadSafeValueContainer(value: [], queue: queue)
    self.currentDownloadProgress = ThreadSafeValueContainer(value: 0.0, queue: queue)
  }
  
  /// Adds a fixed weight download task with given weight.
  ///
  /// - Note: Adds the task as flexible weight if the weight provided is less than 0.0 or greater than 1.0, or
  /// if after adding the task the combined weight of all the fixed weight tasks becomes more than 1.0.
  ///
  /// Does not add the process in following situations:
  /// 1. The item has already been added.
  /// 2. The download progress has already reached 100%.
  /// 3. The total weight of fixed weight items is 1.0
  func addFixedWeightTask(with url: URL, weight incomingWeight: Double) {
    // Added wrong weight amount. Adding it as a flexible weight item instead
    if (incomingWeight < 0.0 || incomingWeight > 1.0) {
      addFlexibleWeightTask(with: url)
      return
    }
    
    // Added a task with zero weight, which, be definition, won't affect our
    // progress.
    if incomingWeight == 0.0 {
      return
    }
    
    // If adding the item will result in weight higher than 1.0, we add it as a
    // flexible weight item
    let currentFixedWeight = combinedWeightOfAllFixedWeightTasks()
    guard currentFixedWeight + incomingWeight <= 1.0 else {
      addFlexibleWeightTask(with: url)
      return
    }
    
    addTask(DownloadTask(url: url, weight: incomingWeight, isFixedWeight: true))
  }
  
  /// Adds a flexible weight download task. Upon adding, the weight of this task, along with all the other
  /// unfinished flexible weight tasks, will change so that the total  weight of all tasks does not exceed 1.0.
  ///
  /// - Note: When more tasks are added, the weight of this task, if not finished, along with all the other
  /// unfinished flexible weight tasks, will change so that the total  weight of all tasks does not exceed 1.0.
  ///
  /// Does not add the process in following situations
  /// 1. The item has already been added.
  /// 2. The download progress has already reached 100%.
  /// 3. The total weight of fixed weight items is 1.0
  func addFlexibleWeightTask(with url: URL) {
    addTask(DownloadTask(url: url, weight: 1.0, isFixedWeight: false))
  }
  
  private func addTask(_ task: DownloadTask) {
    // Already reached 100 %.
    guard
      let progress = currentDownloadProgress.value,
      progress < 1.0
    else {
      return
    }
    
    // Weight of all fixed items exceeds or is equal to 1.0.
    let totalFixedWeight = combinedWeightOfAllFixedWeightTasks()
    guard totalFixedWeight < 1.0 else {
      return
    }
    
    // We already have a value with same url.
    if allTasks.value?.contains(where: { $0.url == task.url }) ?? false {
      return
    }
    
    allTasks.value?.append(task)
    reallocateWeightOfUnfinishedFlexibleWeightTasks()
    updateProgressListener()
  }
  
  func didFinishTask(with url: URL) {
    allTasks.value?.first { $0.url == url }?.isCompleted = true
    updateProgressListener()
  }
  
  // MARK: Private Methods
  private func reallocateWeightOfUnfinishedFlexibleWeightTasks() {
    let currentFixedWeight = combinedWeightOfAllFixedWeightTasks()
    guard currentFixedWeight < 1.0 else {
      return
    }
    
    let unfinishedFlexibleWeightTasks = getUnfinishedFlexibleWeightTasks()
    
    guard !unfinishedFlexibleWeightTasks.isEmpty else {
      return
    }
    
    let unfinishedFlexibleWeightTasksCount = unfinishedFlexibleWeightTasks.count
    let newFlexibleWeightPerTask = (1.0 - currentFixedWeight)/Double(unfinishedFlexibleWeightTasksCount)
    
    unfinishedFlexibleWeightTasks.forEach {
      $0.weight = newFlexibleWeightPerTask
    }
  }
  
  private func updateProgressListener() {
    let completedTasks = allTasks.value?.filter { $0.isCompleted } ?? []
    guard !completedTasks.isEmpty else {
      return
    }
    
    let completedTasksWeight = completedTasks.reduce(0.0) { $0 + $1.weight }
    // Makes sure the value stays between 0.0 & 1.0
    let progress = min(1.0, max(0.0, completedTasksWeight))
    
    self.currentDownloadProgress.value = progress
    progressListener?.downloadProgressDidUpdate(progress)
  }
  
  private func getAllDownloadTasks() -> [DownloadTask] {
    return allTasks.value ?? []
  }
  
  private func getUnfinishedFlexibleWeightTasks() -> [DownloadTask] {
    return getAllDownloadTasks()
      .filter { !$0.isFixedWeight }
      .filter { !$0.isCompleted }
  }
  
  private func getAllFixedWeightTasks() -> [DownloadTask] {
    return getAllDownloadTasks().filter { $0.isFixedWeight }
  }
  
  private func combinedWeightOfAllFixedWeightTasks() -> Double {
    return getAllFixedWeightTasks()
      .reduce(0.0) { $0 + $1.weight }
  }
  
}

// MARK: Helper methods for testing
extension NYPLAxisDownloadProgress {
  
  func test_reset() {
    allTasks.value = []
  }
  
  func test_getWeightForProcess(withURL url: URL) -> Double? {
    return allTasks.value?.first { $0.url == url }?.weight
  }
  
}

private class DownloadTask {
  let url: URL
  var weight: Double
  var isCompleted: Bool
  let isFixedWeight: Bool
  
  init(url: URL, weight: Double, isFixedWeight: Bool) {
    self.url = url
    self.weight = weight
    self.isFixedWeight = isFixedWeight
    self.isCompleted = false
  }
}
