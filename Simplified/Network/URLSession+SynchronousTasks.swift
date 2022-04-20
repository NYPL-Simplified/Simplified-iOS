//
//  URLSession+SynchronousTasks.swift
//  Simplified
//
//  Created by Ettore Pasquini on 3/30/22.
//  Copyright © 2022 NYPL. All rights reserved.
//

import Foundation

extension URLSession {

  /// Submits a request and waits synchronously until the request is completed.
  ///
  /// - Important: This method blocks the current thread until a response is
  /// received from the server or a timeout occurs.
  /// - Parameter req: The request to be executed.
  /// - Returns: A tuple with the response data, response object and error.
  func synchronouslyExecute(_ req: URLRequest) -> (Data?, URLResponse?, Error?) {
    var data: Data?
    var response: URLResponse?
    var error: Error?

    let semaphore = DispatchSemaphore(value: 0)

    let dataTask = self.dataTask(with: req) {
      data = $0
      response = $1
      error = $2

      semaphore.signal()
    }
    dataTask.resume()

    _ = semaphore.wait(timeout: .distantFuture)

    return (data, response, error)
  }
}
