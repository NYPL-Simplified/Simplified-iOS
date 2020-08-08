import CommonCrypto

class RSAUtils {
    class func stripPEMKeyHeader(_ key: String) -> String {
        let fullRange = NSRange(location: 0, length: key.lengthOfBytes(using: .utf8))
        let regExp = try! NSRegularExpression(pattern: "(-----BEGIN.*?-----)|(-----END.*?-----)|\\s+", options: [])
        return regExp.stringByReplacingMatches(in: key, options: [], range: fullRange, withTemplate: "")
    }
}
