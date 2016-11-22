import Foundation

/// A `Configuration` instance is used by applications to set up a new card registration
/// flow.
@objc public final class CardCreatorConfiguration: NSObject {
  /// The base URL for all API requests, e.g. the base URL for
  /// "http://qa.patrons.librarysimplified.org/v1/validate/username" is
  /// "http://qa.patrons.librarysimplified.org/v1".
  public let endpointURL: URL
  /// The username to be provided via basic authentication to the API endpoint.
  public let endpointUsername: String
  /// The password to be provided via basic authentication to the API endpoint.
  public let endpointPassword: String
  /// The timeout to use for all requests to the API endpoint.
  public let requestTimeoutInterval: TimeInterval
  /// This will always be called on the main thread. It will only be called in the event
  /// of a successful registration.
  let completionHandler: (_ username: String, _ PIN: String, _ userInitiated: Bool) -> Void
  
  public init(
    endpointURL: URL,
    endpointUsername: String,
    endpointPassword: String,
    requestTimeoutInterval: TimeInterval,
    completionHandler: @escaping (_ username: String, _ PIN: String, _ userInitiated: Bool) -> Void)
  {
    self.endpointURL = endpointURL
    self.endpointUsername = endpointUsername
    self.endpointPassword = endpointPassword
    self.requestTimeoutInterval = requestTimeoutInterval
    self.completionHandler = completionHandler
    super.init()
  }
}
