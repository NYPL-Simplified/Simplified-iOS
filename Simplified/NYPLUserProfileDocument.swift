import Foundation

@objcMembers public class UserProfileDocument : NSObject, Codable {
  static let parseErrorKey: String = "NYPLParseProfileErrorKey"
  static let parseErrorDescription: String = "NYPLParseProfileErrorDescription"
  static let parseErrorCodingPath: String = "NYPLParseProfileErrorCodingPath"

  static let decodingErrorCodeInvalid: Int = 4864
  static let decodingErrorCodeNotFound: Int = 4865
    
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
    
  enum NYPLParseProfileErrorKey: Int {
    case dataCorrupted = 1001
    case typeMismatch = 1002
    case valueNotFound = 1003
    case keyNotFound = 1004
  }
  
  func toJson() -> String {
    let jsonEncoder = JSONEncoder()
    let jsonData = try? jsonEncoder.encode(self)
    if (jsonData != nil) {
      return String(data: jsonData!, encoding: .utf8) ?? ""
    }
    return ""
  }
  
  @objc static func fromData(_ data: Data) throws -> UserProfileDocument {
    let jsonDecoder = JSONDecoder()
    jsonDecoder.keyDecodingStrategy = .useDefaultKeys
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    jsonDecoder.dateDecodingStrategy = .formatted(dateFormatter)
    
    do {
      return try jsonDecoder.decode(UserProfileDocument.self, from: data)
    } catch let DecodingError.dataCorrupted(context) {
      throw NSError(domain: NSCocoaErrorDomain,
                    code: decodingErrorCodeInvalid,
                    userInfo: [parseErrorKey: NYPLParseProfileErrorKey.dataCorrupted.rawValue,
                               parseErrorDescription: context.debugDescription,
                               parseErrorCodingPath: context.codingPath])
    } catch let DecodingError.typeMismatch(_, context) {
      throw NSError(domain: NSCocoaErrorDomain,
                    code: decodingErrorCodeInvalid,
                    userInfo: [parseErrorKey: NYPLParseProfileErrorKey.typeMismatch.rawValue,
                               parseErrorDescription: context.debugDescription,
                               parseErrorCodingPath: context.codingPath])
    } catch let DecodingError.valueNotFound(_, context) {
      throw NSError(domain: NSCocoaErrorDomain,
                    code: decodingErrorCodeNotFound,
                    userInfo: [parseErrorKey: NYPLParseProfileErrorKey.valueNotFound.rawValue,
                               parseErrorDescription: context.debugDescription,
                               parseErrorCodingPath: context.codingPath])
    } catch let DecodingError.keyNotFound(_, context) {
      throw NSError(domain: NSCocoaErrorDomain,
                    code: decodingErrorCodeNotFound,
                    userInfo: [parseErrorKey: NYPLParseProfileErrorKey.keyNotFound.rawValue,
                               parseErrorDescription: context.debugDescription,
                               parseErrorCodingPath: context.codingPath])
    }
  }
}
