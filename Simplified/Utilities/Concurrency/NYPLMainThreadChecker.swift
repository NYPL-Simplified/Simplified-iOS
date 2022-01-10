//
//  NYPLMainThreadChecker.swift
//  SimplyE
//
//  Created by Ettore Pasquini on 2/7/20.
//  Copyright © 2020 NYPL. All rights reserved.
//

import Foundation
import Dispatch

@objc class NYPLMainThreadRun: NSObject {

  /// Makes sure to run the specified work item synchronously on the
  /// main __thread__.
  /// - Note: If the caller was already executing on the main thread,
  /// the block is executed immediately on the same queue of the caller, which
  /// may not be the main queue.
  /// - See: https://github.com/apple/swift-corelibs-libdispatch/commit/e64e4b962e1f356d7561e7a6103b424f335d85f6
  /// - Parameters:
  ///   - work: The block to run on the main thread.
  static func sync(_ work: () -> Void) {
    if Thread.isMainThread {
      work()
    } else {
      DispatchQueue.main.sync {
        work()
      }
    }
  }

  /// Runs the specified work item on the main thread asynchrounously if we
  /// are not already on the main thread. Otherwise, the work block is run
  /// synchronously.
  /// - Note: If the caller was already executing on the main thread,
  /// the block is executed immediately on the same queue of the caller, which
  /// may not be the main queue.
  /// - See: https://github.com/apple/swift-corelibs-libdispatch/commit/e64e4b962e1f356d7561e7a6103b424f335d85f6
  /// - Parameters:
  ///   - work: The block to run on the main thread.
  @objc static func asyncIfNeeded(_ work: @escaping () -> Void) {
    if Thread.isMainThread {
      work()
    } else {
      DispatchQueue.main.async {
        work()
      }
    }
  }
}

