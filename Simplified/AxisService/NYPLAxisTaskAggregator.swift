//
//  NYPLAxisTaskAggregator.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-06-22.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

/// `Task aggregator and synchronizer`
///
/// For a group of tasks such as [taskA, taskB, taskC, taskD], the execution order would be taskA(), taskB(),
/// taskC(), taskD().
///
/// Tasks run synchronously so that taskD won't execute until taskC succeeds, and taskC won't execute until
/// taskB succeeds.
///
/// At any point in time when a task fails, subsequent tasks don't get called. e.g. if taskB fails, taskC and taskD
/// will never get called.
///
/// - Note: The added tasks retain the closure. This can lead to retain cycles. However, as soon as a task
/// is executed (succeeds or fails), the retain cycle is broken.
///
///       let aggregator = NYPLAxisTaskAggregator()
///
///       let taskA = NYPLAxisTask() { task in
///         // some code that determines whether the task should succeed or fail
///         task.succeeded() or task.failed(with error)
///        }
///
///       let taskB = NYPLAxisTask() { task in
///       // some code that determines whether the task should succeed or fail
///         task.succeeded() or task.failed(with error)
///        }
///
///       aggregator
///         .addTasks([taskA, taskB])
///         .run()
///         .onCompletion { result in
///           switch result {
///             case .success:
///             // Do something with success
///             case .failure(let error):
///             // handle error
///           }
///
class NYPLAxisTaskAggregator {
  private let tasks: ThreadSafeValueContainer<[NYPLAxisTask]>
  private let cancelled: ThreadSafeValueContainer<Bool>
  private var completion: ((Result<Bool, NYPLAxisError>) -> Void)?
  private var alreadyCompleted: Result<Bool, NYPLAxisError>?

  private var getTasks: [NYPLAxisTask] {
    return tasks.value ?? []
  }

  private var isCancelled: Bool {
    return cancelled.value ?? true
  }

  init(queue: DispatchQueue = DispatchQueue(label: "NYPLAxisTaskAggregator")) {
    self.tasks = ThreadSafeValueContainer(value: [], queue: queue)
    self.cancelled = ThreadSafeValueContainer(value: false, queue: queue)
  }

  /// Add a task to the list of tasks
  func addTask(_ task: NYPLAxisTask) -> NYPLAxisTaskAggregator {
    self.tasks.value = getTasks + [task]
    return self
  }

  /// Add tasks to the list of tasks
  func addTasks(_ tasks: [NYPLAxisTask]) -> NYPLAxisTaskAggregator {
    self.tasks.value = getTasks + tasks
    return self
  }
  
  /// Start executing tasks
  @discardableResult
  func run() -> NYPLAxisTaskAggregator {
    guard !isCancelled else {
      return self
    }
    
    guard !getTasks.isEmpty else {
      alreadyCompleted = .success(true)
      completion?(.success(true))
      return self
    }
    
    var currentTasks = getTasks
    let taskToExecute = currentTasks.removeFirst()
    self.tasks.value = currentTasks
    
    taskToExecute.execute { (result) in
      switch result {
      case .success:
        self.run()
      case.failure(let error):
        self.taskFailed(with: error)
      }
    }
    return self
  }
  
  private func taskFailed(with error: NYPLAxisError) {
    tasks.value = []
    alreadyCompleted = .failure(error)
    completion?(.failure(error))
    completion = nil
  }
  
  /// Add a completion block which executes after all the tasks have executed or upon failing a task.
  func onCompletion(_ completion: @escaping (Result<Bool, NYPLAxisError>) -> Void) {
    if let result = alreadyCompleted {
      completion(result)
    } else {
      self.completion = completion
    }
  }
  
  /// Cancel all tasks
  func cancelAllTasks(with error: NYPLAxisError) {
    cancelled.value = true
    taskFailed(with: error)
  }
  
}

class NYPLAxisTask {
  private let closure: ((NYPLAxisTask) -> Void)
  private var completion: ((Result<Bool, NYPLAxisError>) -> Void)?
  
  init(_ closure: @escaping (NYPLAxisTask) -> Void) {
    self.closure = closure
  }
  
  func execute(_ completion: @escaping (Result<Bool, NYPLAxisError>) -> Void) {
    self.completion = completion
    closure(self)
  }
  
  /// Task succeeded
  func succeeded() {
    completion?(.success(true))
  }
  
  /// Task failed with given error
  func failed(with error: NYPLAxisError) {
    completion?(.failure(error))
  }
  
  /// Task failed with given error
  func failed(with error: Error) {
    failed(with: .other(error))
  }
  
  /// Take action based on the result received
  func processResult(_ result: Result<Bool, Error>) {
    processResult(result.mapError {
      return $0 as? NYPLAxisError ?? NYPLAxisError.other($0)
    })
  }
  
  /// Take action based on the result received
  func processResult(_ result: Result<Bool, NYPLAxisError>) {
    switch result {
    case .success:
      succeeded()
    case .failure(let error):
      failed(with: error)
    }
  }
  
}
