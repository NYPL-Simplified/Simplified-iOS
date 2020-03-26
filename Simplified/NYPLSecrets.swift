import Foundation

enum AudioBookVendors: String {
  case cantook = "cantook"
}

enum NYPLSecrets {
  private static let salt: [UInt8] = [0]

  static var cardCreator:String? {
    let encoded: [UInt8] = [0]
    return decode(encoded, cipher: salt)
  }
    
  static var cardCreatorInfo:[String:Any] {
    return [:]
  }

  static func feedbookKeys(forVendor name: AudioBookVendors) -> String? {
    let allKeys : [String: [UInt8]] = [:]
    guard let encoded = allKeys[name.rawValue] else { return nil }
    return decode(encoded, cipher: salt)
  }

  static func feedbookInfo(forVendor name: AudioBookVendors) -> [String:Any] {
    let info : [String: [String:Any]] = [:]
    return info[name.rawValue] ?? [:]
  }

  static func decode(_ encoded: [UInt8], cipher: [UInt8]) -> String? {
    var decrypted = [UInt8]()
    return String(bytes: decrypted, encoding: .utf8)
  }
}
