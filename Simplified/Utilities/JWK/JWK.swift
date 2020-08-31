/*
 Copyright 2017 IBM Corp.
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */


import Foundation

public struct JWK: Codable {
    var kty: String                // key type
    var id: Int?                    // key id
    var use: String?                // key usage
    var alg: String?                // Algorithm
    
    var x5u: String?                // (X.509 URL) Header Parameter
    var x5t: String?                // (X.509 Certificate Thumbprint) Header Parameter
    var x5c: String?                // (X.509 Certificate Chain) Header Parameter
    
    // RSA keys
    // Represented as the base64url encoding of the value’s unsigned big endian representation as an octet sequence.
    var n: String?                    // modulus
    var e: String?                  // exponent
    
    var d: String?                  // private exponent
    var p: String?                  // first prime factor
    var q: String?                  // second prime factor
    var dp: String?                 // first factor CRT exponent
    var dq: String?                 // second factor CRT exponent
    var qi: String?                 // first CRT coefficient
    var oth: othType?               // other primes info
    
    // EC DSS keys
    var crv: String?
    var x: String?
    var y: String?
    
    enum othType: String, Codable {
        case r
        case d
        case t
    }
}
