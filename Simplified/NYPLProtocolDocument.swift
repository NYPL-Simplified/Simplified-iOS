import Foundation

@objcMembers public class ProtocolDocument : NSObject, Codable {
  @objc @objcMembers public class DRMObject : NSObject, Codable {
    let vendor: String?
    let clientToken: String?
    let serverToken: String?
    let scheme: String?
    
    var licensor: [String : String] {
      return [
        "vendor": vendor ?? "",
        "clientToken": clientToken ?? ""
      ]
    }
    
    enum CodingKeys: String, CodingKey {
      case vendor  = "drm:vendor"
      case clientToken = "drm:clientToken"
      case serverToken = "drm:serverToken"
      case scheme = "drm:scheme"
    }
  }
  
  @objc public class Link : NSObject, Codable {
    let href: String
    let type: String?
    let rel: String?
    let templated: Bool?
  }
  
  @objc public class Settings : NSObject, Codable {
    let synchronizeAnnotations: Bool?

    enum CodingKeys: String, CodingKey {
      case synchronizeAnnotations  = "simplified:synchronize_annotations"
    }
  }
  
  let authorizationIdentifier: String?
  let drm: [DRMObject]?
  let links: [Link]?
  let authorizationExpires: Date?
  let settings: Settings?
  
  enum CodingKeys: String, CodingKey {
    case authorizationIdentifier = "simplified:authorization_identifier"
    case drm = "drm"
    case links = "links"
    case authorizationExpires = "simplified:authorization_expires"
    case settings = "settings"
  }
  
  func toJson() -> String {
    let jsonEncoder = JSONEncoder()
    let jsonData = try? jsonEncoder.encode(self)
    if (jsonData != nil) {
      return String(data: jsonData!, encoding: .utf8) ?? ""
    }
    return ""
  }
  
  @objc static func fromData(_ data: Data) throws -> ProtocolDocument {
    let jsonDecoder = JSONDecoder()
    jsonDecoder.keyDecodingStrategy = .useDefaultKeys
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    jsonDecoder.dateDecodingStrategy = .formatted(dateFormatter)
    
    return try jsonDecoder.decode(ProtocolDocument.self, from: data)
  }
}
