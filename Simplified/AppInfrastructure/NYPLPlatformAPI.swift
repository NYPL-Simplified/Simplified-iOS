import Foundation

struct NYPLPlatformAPI {
  /// These is hitting the production ILS.
  static let oauthTokenURL = URL(string: "https://isso.nypl.org/oauth/token")!

  /// These is hitting the production ILS.
  /// Use `qa-platform.*` for hitting QA ILS endpoints.
  static let baseURL = URL(string: "https://platform.nypl.org/api/v0.3/")!
}
