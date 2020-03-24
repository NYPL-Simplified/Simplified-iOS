import Foundation

enum NYPLSecrets {
  private static let salt: [UInt8] = [0]

  static var feedbooks:String {
    let encoded: [UInt8] = [0]
    return decode(encoded, cipher: salt)
  }

  static var feedbooksInfo:[String:Any] {
    return [:]
  }

  static var cardCreator:String {
    let encoded: [UInt8] = [0]
    return decode(encoded, cipher: salt)
  }

  static var cardCreatorInfo:[String:Any] {
    return [:]
  }

  static func decode(_ encoded: [UInt8], cipher: [UInt8]) -> String {
    var decrypted = [UInt8]()

    return String(bytes: decrypted, encoding: .utf8)!
  }
}
