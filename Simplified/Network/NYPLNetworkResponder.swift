//
//  NYPLNetworkResponder.swift
//  SimplyE
//
//  Created by Ettore Pasquini on 3/22/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

fileprivate struct NYPLNetworkTaskInfo {
  var progressData: Data
  var startDate: Date
  var completion: ((NYPLResult<Data>) -> Void)

  //----------------------------------------------------------------------------
  init(completion: (@escaping (NYPLResult<Data>) -> Void)) {
    self.progressData = Data()
    self.startDate = Date()
    self.completion = completion
  }
}

/// This class responds to URLSession events related to the tasks being
/// issued on the URLSession, keeping a tally of the related completion
/// handlers in a thread-safe way.
class NYPLNetworkResponder: NSObject {
  typealias TaskID = Int

  private var taskInfo: [TaskID: NYPLNetworkTaskInfo]

  /// Protects access to `taskInfo` to ensure thread-safety.
  private let taskInfoLock: NSRecursiveLock

  //----------------------------------------------------------------------------
  override init() {
    self.taskInfo = [Int: NYPLNetworkTaskInfo]()
    self.taskInfoLock = NSRecursiveLock()
    super.init()
  }

  //----------------------------------------------------------------------------
  func addCompletion(_ completion: @escaping (NYPLResult<Data>) -> Void,
                     taskID: TaskID) {
    taskInfoLock.lock()
    defer {
      taskInfoLock.unlock()
    }

    taskInfo[taskID] = NYPLNetworkTaskInfo(completion: completion)
  }
}

// MARK: - URLSessionDelegate
extension NYPLNetworkResponder: URLSessionDelegate {
  //----------------------------------------------------------------------------
  func urlSession(_ session: URLSession, didBecomeInvalidWithError err: Error?) {
    if let err = err {
      NYPLErrorLogger.logError(err, summary: "URLSession became invalid")
    } else {
      NYPLErrorLogger.logError(withCode: .invalidURLSession,
                               summary: "URLSessionDelegate: session became invalid")
    }

    taskInfoLock.lock()
    defer {
      taskInfoLock.unlock()
    }

    taskInfo.removeAll()
  }
}

// MARK: - URLSessionDataDelegate
extension NYPLNetworkResponder: URLSessionDataDelegate {

  //----------------------------------------------------------------------------
  func urlSession(_ session: URLSession,
                  dataTask: URLSessionDataTask,
                  didReceive data: Data) {
    taskInfoLock.lock()
    defer {
      taskInfoLock.unlock()
    }

    var currentTaskInfo = taskInfo[dataTask.taskIdentifier]
    currentTaskInfo?.progressData.append(data)
    taskInfo[dataTask.taskIdentifier] = currentTaskInfo
  }

  //----------------------------------------------------------------------------
  func urlSession(_ session: URLSession,
                  dataTask: URLSessionDataTask,
                  willCacheResponse proposedResponse: CachedURLResponse,
                  completionHandler: @escaping (CachedURLResponse?) -> Void) {

    guard let httpResponse = proposedResponse.response as? HTTPURLResponse else {
      completionHandler(proposedResponse)
      return
    }

    if httpResponse.hasSufficientCachingHeaders {
      completionHandler(proposedResponse)
    } else {
      let newResponse = httpResponse.modifyingCacheHeaders()
      completionHandler(CachedURLResponse(response: newResponse,
                                          data: proposedResponse.data))
    }
  }

  //----------------------------------------------------------------------------
  func urlSession(_ session: URLSession,
                  task: URLSessionTask,
                  didCompleteWithError networkError: Error?) {
    let taskID = task.taskIdentifier
    var logMetadata: [String: Any] = [
      "currentRequest": task.currentRequest?.loggableString ?? "N/A",
      "taskID": taskID,
    ]

    taskInfoLock.lock()
    guard let currentTaskInfo = taskInfo.removeValue(forKey: taskID) else {
      taskInfoLock.unlock()
      NYPLErrorLogger.logNetworkError(
        networkError,
        code: .noTaskInfoAvailable,
        summary: "Network layer error: task info unavailable",
        request: task.originalRequest,
        response: task.response,
        message: "No task info available for task \(taskID). Completion closure could not be called.",
        metadata: logMetadata)
      return
    }
    taskInfoLock.unlock()

    let responseData = currentTaskInfo.progressData
    let elapsed = Date().timeIntervalSince(currentTaskInfo.startDate)
    logMetadata["elapsedTime"] = elapsed
    Log.info(#file, "Task \(taskID) completed, elapsed time: \(elapsed) sec")

    // attempt parsing of Problem Document
    if task.response?.isProblemDocument() ?? false {
      let problemDocError = task.parseAndLogError(fromProblemDocumentData: responseData,
                                                  networkError: networkError,
                                                  logMetadata: logMetadata)
      currentTaskInfo.completion(.failure(problemDocError, task.response))
      return
    }

    // no problem document, but if we have an error it's still a failure
    if let networkError = networkError {
      currentTaskInfo.completion(.failure(networkError as NYPLUserFriendlyError, task.response))

      // logging the error after the completion call so that the error report
      // will include any eventual logging done in the completion handler.
      NYPLErrorLogger.logNetworkError(
        networkError,
        summary: "Network task completed with error",
        request: task.originalRequest,
        response: task.response,
        metadata: logMetadata)
      return
    }

    // no problem document nor error, but response could still be a failure
    if let httpResponse = task.response as? HTTPURLResponse {
      guard !httpResponse.isFailure() else {
        logMetadata["response"] = httpResponse
        logMetadata[NSLocalizedDescriptionKey] = NSLocalizedString("UnknownRequestError", comment: "A generic error message for when a network request fails")
        let err = NSError(domain: "Api call with failure HTTP status",
                          code: NYPLErrorCode.responseFail.rawValue,
                          userInfo: logMetadata)
        currentTaskInfo.completion(.failure(err, task.response))
        NYPLErrorLogger.logNetworkError(code: NYPLErrorCode.responseFail,
                                        summary: "Network request failed: server error response",
                                        request: task.originalRequest,
                                        metadata: logMetadata)
        return
      }
    }

    currentTaskInfo.completion(.success(responseData, task.response))
  }
}

//------------------------------------------------------------------------------
// MARK: - URLSessionTask extensions

extension URLSessionTask {
  //----------------------------------------------------------------------------
  fileprivate func parseAndLogError(fromProblemDocumentData responseData: Data,
                                    networkError: Error?,
                                    logMetadata: [String: Any]) -> NYPLUserFriendlyError {
    let parseError: Error?
    let code: NYPLErrorCode
    let returnedError: NYPLUserFriendlyError
    var logMetadata = logMetadata

    do {
      let problemDoc = try NYPLProblemDocument.fromData(responseData)
      returnedError = error(fromProblemDocument: problemDoc)
      parseError = nil
      code = NYPLErrorCode.problemDocAvailable
      logMetadata["problemDocument"] = problemDoc.dictionaryValue
    } catch (let caughtParseError) {
      parseError = caughtParseError
      code = NYPLErrorCode.parseProblemDocFail
      let responseString = String(data: responseData, encoding: .utf8) ?? "N/A"
      logMetadata["problemDocument (parse failed)"] = responseString
      if let networkError = networkError as NYPLUserFriendlyError? {
        returnedError = networkError
      } else {
        returnedError = caughtParseError as NYPLUserFriendlyError
      }
    }

    if let networkError = networkError {
      logMetadata["urlSessionError"] = networkError
    }

    NYPLErrorLogger.logNetworkError(parseError,
                                    code: code,
                                    summary: "Network request failed: Problem Document available",
                                    request: originalRequest,
                                    response: response,
                                    metadata: logMetadata)

    return returnedError
  }

  //----------------------------------------------------------------------------
  func error(fromProblemDocument problemDoc: NYPLProblemDocument) -> NSError {
    var userInfo = [String: Any]()
    if let currentRequest = currentRequest {
      userInfo["taskCurrentRequest"] = currentRequest
    }
    if let originalRequest = originalRequest {
      userInfo["taskOriginalRequest"] = originalRequest
    }
    if let response = response {
      userInfo["response"] = response
    }

    let err = NSError.makeFromProblemDocument(
      problemDoc,
      domain: "Api call failure: problem document available",
      code: NYPLErrorCode.apiCall.rawValue,
      userInfo: userInfo)

    return err
  }
}

//----------------------------------------------------------------------------
// MARK: - URLSessionTaskDelegate
extension NYPLNetworkResponder: URLSessionTaskDelegate {
  func urlSession(_ session: URLSession,
                  task: URLSessionTask,
                  didReceive challenge: URLAuthenticationChallenge,
                  completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
  {
    //        NYPLLOG_F(@"NSURLSessionTask: %@. Challenge Received: %@",
    //                   task.currentRequest.URL.absoluteString,
    //                   challenge.protectionSpace.authenticationMethod);
    
    NYPLBasicAuth.authHandler(challenge: challenge, completionHandler: completionHandler)
  }
}
