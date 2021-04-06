//
//  NYPLMultipleFilesDownlaoder.swift
//  Simplified
//
//  Created by Raman Singh on 2021-04-01.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

enum DownloadError: Error {
  case packetFetchError(String) // Error occured while downloading
  case wrongOrder(String) // Add complete block with wrong order
}

@objc protocol DownloadProcessProtocol {
  
  /// Share downloding progress with outside
  ///
  /// - parameter percent:  Download percentage of current file
  func downloadingProgress(_ percent: Float, fileName: String)
  
  /// Get called when download complete
  func downloadSucceeded(_ fileName: String)
  
  /// Get called when error occured while download.
  ///
  /// - parameter error: Download error occurred by URLSession's download task
  func downloadWithError(_ error: Error?, fileName: String)
  
}

/// Manager of asynchronous download `Operation` objects
@objcMembers class NYPLMultipleFilesDownlaoder: NSObject {
  
  /// Dictionary of operations, keyed by the `taskIdentifier` of the `URLSessionTask`
  fileprivate var operations = [Int: DownloadOperation]()
  
  /// Set  download count that can execute at the same time.
  /// Default is 1 to make a serial download.
  public static var maxOperationCount = 1
  
  /// Serial NSOperationQueue for downloads
  private let queue: OperationQueue = {
    let _queue = OperationQueue()
    _queue.name = "NYPLMultipleFilesDownlaoder.downloadQueue"
    _queue.maxConcurrentOperationCount = maxOperationCount
    return _queue
  }()
  
  /// Delegate-based NSURLSession for DownloadManager
  lazy var session: URLSession = {
    let configuration = URLSessionConfiguration.default
    return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
  }()
  
  /// Track the download process
  var  processDelegate : DownloadProcessProtocol?
  
  /// Add download links
  ///
  /// - parameter url: The file's download URL
  ///
  /// - returns:  A downloadOperation of the operation that was queued
  @discardableResult
  @objc func addDownload(_ url: URL) -> DownloadOperation {
    let operation = DownloadOperation(session: session, url: url)
    operations[operation.task.taskIdentifier] = operation
    queue.addOperation(operation)
    return operation
  }
  
  /// Add download links
  /// - Parameters:
  ///   - url: The file's download URL
  ///   - completion: Block of code to execute upon completion
  /// - Returns: A downloadOperation of the operation that was queued
  @objc func addDownload(_ url: URL, completion: (() -> (Void))?) -> DownloadOperation {
    let operation = DownloadOperation(session: session, url: url)
    operations[operation.task.taskIdentifier] = operation
    queue.addOperation(operation)
    let onCompletion = BlockOperation {
      completion?()
    }
    onCompletion.addDependency(operation)
    OperationQueue.main.addOperation(onCompletion)
    return operation
  }
  
  
  
  /// Cancel all queued operations
  func cancelAll() {
    queue.cancelAllOperations()
  }
}

// MARK: URLSessionDownloadDelegate methods
extension NYPLMultipleFilesDownlaoder: URLSessionDownloadDelegate {
  
  func urlSession(_ session: URLSession,
                  downloadTask: URLSessionDownloadTask,
                  didFinishDownloadingTo location: URL) {
    
    operations[downloadTask.taskIdentifier]?.trackDownloadByOperation(session, downloadTask: downloadTask, didFinishDownloadingTo: location)
    
    if let downloadUrl = downloadTask.originalRequest!.url {
      DispatchQueue.main.async { [weak self] in
        self?.processDelegate?.downloadSucceeded(downloadUrl.lastPathComponent)
      }
    }
  }
  
  func urlSession(_ session: URLSession,
                  downloadTask: URLSessionDownloadTask,
                  didWriteData bytesWritten: Int64,
                  totalBytesWritten: Int64,
                  totalBytesExpectedToWrite: Int64) {
    
    operations[downloadTask.taskIdentifier]?.trackDownloadByOperation(session, downloadTask: downloadTask, didWriteData: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
    
    if let downloadUrl = downloadTask.originalRequest!.url {
      let percent = Double(totalBytesWritten)/Double(totalBytesExpectedToWrite)
      DispatchQueue.main.async { [weak self] in
        self?.processDelegate?.downloadingProgress(
          Float(percent),
          fileName:  downloadUrl.lastPathComponent)
      }
    }
  }
  
  func urlSession(_ session: URLSession,
                  task: URLSessionTask,
                  didCompleteWithError error: Error?) {
    
    let key = task.taskIdentifier
    operations[key]?
      .trackDownloadByOperation(session,
                                task: task,
                                didCompleteWithError: error)
    operations.removeValue(forKey: key)
    
    if let downloadUrl = task.originalRequest!.url, error != nil {
      DispatchQueue.main.async { [weak self] in
        self?.processDelegate?.downloadWithError(
          error,
          fileName: downloadUrl.lastPathComponent)
      }
    }
  }
}

// MARK: - Asyncnorous Operations

class AsynchronousOperation : Operation {
  override public var isAsynchronous: Bool {
    return true
  }
  
  private let stateLock = NSLock()
  private var _executing: Bool = false
  override private(set) public var isExecuting: Bool {
    get {
      return stateLock.withCriticalScope {
        _executing
      }
    }
    set {
      willChangeValue(forKey: "isExecuting")
      stateLock.withCriticalScope {
        _executing = newValue
      }
      didChangeValue(forKey: "isExecuting")
    }
  }
  
  private var _finished: Bool = false
  override private(set) public var isFinished: Bool {
    get {
      return stateLock.withCriticalScope {
        _finished
      }
    }
    set {
      willChangeValue(forKey: "isFinished")
      stateLock.withCriticalScope {
        _finished = newValue
      }
      didChangeValue(forKey: "isFinished")
    }
  }
  
  /// Complete the operation
  ///
  /// This will result in the appropriate KVN of isFinished and isExecuting
  public func completeOperation() {
    if isExecuting {
      isExecuting = false
    }
    if !isFinished {
      isFinished = true
    }
  }
  
  override public func start() {
    if isCancelled {
      isFinished = true
      return
    }
    isExecuting = true
    main()
  }
}

private extension NSLock {
  /// Perform closure within lock.
  ///
  /// An extension to `NSLock` to simplify executing critical code.
  ///
  /// - parameter block: The closure to be performed.
  func withCriticalScope<T>(block:() -> T) -> T {
    lock()
    let value = block()
    unlock()
    return value
  }
}

// MARK: - DownloadOperation
class DownloadOperation: AsynchronousOperation {
  
  var task: URLSessionTask
  
  init(session: URLSession, url: URL) {
    task = session.downloadTask(with: url)
    super.init()
  }
  
  override func cancel() {
    task.cancel()
    super.cancel()
  }
  
  override func main() {
    task.resume()
  }
}

// MARK: Track the download progress from Download manager's urlsession
extension DownloadOperation {
  
  /// Download complete. Save file to document directory.
  func trackDownloadByOperation(_ session: URLSession,
                                downloadTask: URLSessionDownloadTask,
                                didFinishDownloadingTo location: URL) {
    
    do {
      let manager = FileManager.default
      let destinationURL = try manager.url(
        for: .documentDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: false)
        .appendingPathComponent(
          downloadTask.originalRequest!.url!.lastPathComponent)
      
      if manager.fileExists(atPath:  destinationURL.path) {
        try manager.removeItem(at: destinationURL)
      }
      try manager.moveItem(at: location, to: destinationURL)
    }
    catch {
      print("\(error)")
    }
    
    completeOperation()
  }
  
  /// Downloading progress.
  func trackDownloadByOperation(_ session: URLSession,
                                downloadTask: URLSessionDownloadTask,
                                didWriteData bytesWritten: Int64,
                                totalBytesWritten: Int64,
                                totalBytesExpectedToWrite: Int64) {
    
    //let progress = Double(totalBytesWritten)/Double(totalBytesExpectedToWrite)
    //print("\(downloadTask.originalRequest!.url!.absoluteString) \(progress)")
  }
  
  /// Download failed.
  func trackDownloadByOperation(_ session: URLSession,
                                task: URLSessionTask,
                                didCompleteWithError error: Error?) {
    if error != nil {
      print("\(String(describing: error))")
    }
    
    completeOperation()
  }
}
