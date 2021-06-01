//
//  ThreadSafeValueContainer.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-06-01.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

class NYPLAxisThreadSafeContainer {
  fileprivate let queue: DispatchQueue
  
  init(queue: DispatchQueue) {
    self.queue = queue
  }
  
}

class ThreadSafeDictionaryContainer<S: Hashable,T>: NYPLAxisThreadSafeContainer {
  
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

class ThreadSafeValueContainer<T>: NYPLAxisThreadSafeContainer {
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
