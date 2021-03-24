import Foundation

extension Data {
  public func base64EncodedStringUrlSafe() -> String {
    return self.base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "\n", with: "")
  }
}
