//
//  NYPLAxisContentDownloader.swift
//  Simplified
//
//  Created by Raman Singh on 2021-04-22.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

protocol NYPLAxisContentDownloading {
  func downloadItem(from url: URL,
                    _ completion: @escaping (Result<Data, Error>) -> Void)
}


/// A content downloader which stops downloading content upon receiving a failure.
class NYPLAxisContentDownloader: NYPLAxisContentDownloading {
  
  private let tasks: ThreadSafeDictionaryContainer<URL, URLSessionDataTask>
  private let handlers: ThreadSafeDictionaryContainer<URL, (Result<Data, Error>) -> Void>
  private let numberOfAttempts: ThreadSafeDictionaryContainer<URL, Int>
  private let errored: ThreadSafeValueContainer<Bool>
  let networkExecutor: NYPLAxisNetworkExecuting
  
  init(networkExecuting: NYPLAxisNetworkExecuting) {
    let queue = DispatchQueue(label: "AxixThreadSafeContainer")
    self.tasks = ThreadSafeDictionaryContainer(queue: queue)
    self.handlers = ThreadSafeDictionaryContainer(queue: queue)
    self.numberOfAttempts = ThreadSafeDictionaryContainer(queue: queue)
    self.errored = ThreadSafeValueContainer(value: false, queue: queue)
    self.networkExecutor = networkExecuting
  }
  
  func downloadItem(from url: URL,
                    _ completion: @escaping (Result<Data, Error>) -> Void) {
    
    // We dont want to download anything if it's already being downloaded or if
    // we experienced an error downloading something before.
    let isErrored = errored.value ?? false
    guard !isErrored, tasks[url] == nil, handlers[url] == nil else {
      return
    }
    
    numberOfAttempts[url] = (self.numberOfAttempts[url] ?? 0) + 1
    handlers[url] = completion
    tasks[url] = self.getTask(for: url)
  }
  
  private func getTask(for url: URL) -> URLSessionDataTask {
    
    let request = URLRequest(url: url,
                             cachePolicy: .reloadIgnoringLocalCacheData,
                             timeoutInterval: networkExecutor.requestTimeout)
    
    let task = networkExecutor.GET(request) { [weak self] (result) in
      guard let self = self else { return }
      switch result {
      case .success(let data):
        let handler = self.handlers[url]
        self.tasks[url] = nil
        self.handlers[url] = nil
        handler?(.success(data))
      case .failure(let error):
        // In poor network conditions, the download might fail on first or
        // second attempt. We retry 2 more times to make sure we don't
        // prematurely stop the download process.
        if
          let attempts = self.numberOfAttempts[url],
          attempts < 3,
          let handler = self.handlers[url] {
          print("NYPLAxisContentDownloader downloading item from \(url.absoluteString) after \(attempts) failed attempts")
          self.tasks[url] = nil
          self.handlers[url] = nil
          self.downloadItem(from: url, handler)
          return
        }
        
        self.errored.value = true
        self.tasks[url] = nil
        let hanler = self.handlers[url]
        self.tasks.forEach {
          $1.cancel()
        }
        self.tasks.removeAll()
        self.handlers.removeAll()
        // Here we perform short-circuiting so that we don't download anything
        // else after receiving a failure since a book with a missing file is
        // unusable.
        hanler?(.failure(error))
      }
    }
    
    return task
  }
  
}

private class ThreadSafeContainer {
  fileprivate let queue: DispatchQueue
  
  init(queue: DispatchQueue) {
    self.queue = queue
  }
  
}

private class ThreadSafeDictionaryContainer<S: Hashable,T>: ThreadSafeContainer {
  
  private var dictionary: [S:T]
  
  init(dictionary:[S:T] = [:], queue: DispatchQueue) {
    self.dictionary = dictionary
    super.init(queue: queue)
  }
  
  subscript(key: S) -> T? {
    get {
      return queue.sync { [weak self] in
        self?.dictionary[key]
      }
    }
    set(newValue) {
      queue.sync { [weak self] in
        self?.dictionary[key] = newValue
      }
    }
  }
  
  func forEach(closure: (S, T) -> Void) {
    queue.sync {
      self.dictionary.forEach {
        closure($0, $1)
      }
    }
  }
  
  func removeAll() {
    queue.sync { [weak self] in
      self?.dictionary.removeAll()
    }
  }
  
}

private class ThreadSafeValueContainer<T>: ThreadSafeContainer {
  private var _value: T
  
  init(value: T, queue: DispatchQueue) {
    self._value = value
    super.init(queue: queue)
  }
  
  var value: T? {
    get {
      return queue.sync { [weak self] in
        self?._value
      }
    }
    set(newValue) {
      queue.sync { [weak self] in
        guard let newValue = newValue else { return }
        self?._value = newValue
      }
    }
  }
  
}
