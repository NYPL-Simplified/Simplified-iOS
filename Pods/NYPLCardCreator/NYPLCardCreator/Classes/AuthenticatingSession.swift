import UIKit

/// This class is a tiny version of `NSURLSession` that will automatically handle
/// authentication with the API endpoint using basic authentication.
final class AuthenticatingSession {
  fileprivate let delegate: Delegate
  fileprivate let URLSession: Foundation.URLSession
  
  init(configuration: CardCreatorConfiguration) {
    self.delegate = Delegate(username: configuration.endpointUsername, password: configuration.endpointPassword)
    self.URLSession = Foundation.URLSession(
      configuration: URLSessionConfiguration.ephemeral,
      delegate: self.delegate,
      delegateQueue: nil)
  }
  
  /// Functionally equivalent to the `NSURLSession` method with the addition of automatic
  /// authentication with the API endpoint.
  func dataTaskWithRequest(
    _ request: URLRequest,
    completionHandler: @escaping (Data?, URLResponse?, NSError?) -> Void) -> URLSessionDataTask
  {
    return self.URLSession.dataTask(with: request, completionHandler: completionHandler as! (Data?, URLResponse?, Error?) -> Void)
  }
  
  /// As with an `NSURLSession`, this or `finishTasksAndInvalidate` must be called else
  /// resources will not be freed.
  func invalidateAndCancel() {
    self.URLSession.invalidateAndCancel()
  }

  /// As with an `NSURLSession`, this or `invalidateAndCancel` must be called else
  /// resources will not be freed.
  func finishTasksAndInvalidate() {
    self.URLSession.finishTasksAndInvalidate()
  }
  
  fileprivate class Delegate: NSObject, URLSessionDelegate {
    fileprivate let username: String
    fileprivate let password: String
    
    init(username: String, password: String) {
      self.username = username
      self.password = password
    }
    
    // TODO: This needs to be declared @objc for reasons I cannot understand. This was
    // discovered only after much pain. I would like an answer.
    @objc func URLSession(
      _ session: Foundation.URLSession,
      task: URLSessionTask,
      didReceiveChallenge challenge: URLAuthenticationChallenge,
                          completionHandler: (Foundation.URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
      if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic {
        if challenge.previousFailureCount > 0 {
          completionHandler(.performDefaultHandling, nil)
        } else {
          completionHandler(.useCredential, URLCredential(
            user: self.username,
            password: self.password,
            persistence: .forSession))
        }
      } else {
        completionHandler(.rejectProtectionSpace, nil)
      }
    }
  }
}
