// Adapted from: https://stackoverflow.com/a/31932898/9964065
// TODO: Migrate to new Crypto API coming soon

import Foundation
import CommonCrypto

extension String {
  public func md5() -> Data {
    let messageData = self.data(using:.utf8)!
    var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
    
    _ = digestData.withUnsafeMutableBytes { digestBytes in
      messageData.withUnsafeBytes { messageBytes in
        CC_MD5(messageBytes, CC_LONG(messageData.count), digestBytes)
      }
    }
    
    return digestData
  }

  public func md5hex() -> String {
    return md5().map { String(format: "%02hhx", $0) }.joined()
  }
}

@objc extension NSString {
  public func md5String() -> NSString {
    return (self as String).md5hex() as NSString
  }
}
