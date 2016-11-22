import Foundation

final class ValidateUsernameResponse {
  enum Response {
    case invalidUsername
    case unavailableUsername
    case availableUsername
  }
  
  class func responseWithData(_ data: Data) -> Response? {
    guard
      let JSONObject = try? JSONSerialization.jsonObject(with: data, options: []) as! [String: AnyObject],
      let type = JSONObject["type"] as? String
      else { return nil }
    
    switch type {
    case "invalid-username":
      return .invalidUsername
    case "unavailable-username":
      return .unavailableUsername
    case "available-username":
      return .availableUsername
    default:
      break
    }
    
    return nil
  }
}
