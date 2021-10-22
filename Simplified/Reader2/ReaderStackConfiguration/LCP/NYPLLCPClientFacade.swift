//
//  NYPLLCPClientFacade.swift
//  Simplified
//
//  Created by Ettore Pasquini on 4/27/21.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

#if LCP

import R2LCPClient
import ReadiumLCP

let lcpService = LCPService(client: NYPLLCPClient())

/// Facade to the private R2LCPClient.framework.
///
/// This is required by the current LCP implementation in R2.
/// 
/// - See: https://git.io/J3eW8
class NYPLLCPClient: ReadiumLCP.LCPClient {

  func createContext(jsonLicense: String, hashedPassphrase: String, pemCrl: String) throws -> LCPClientContext {
    return try R2LCPClient.createContext(jsonLicense: jsonLicense, hashedPassphrase: hashedPassphrase, pemCrl: pemCrl)
  }

  func decrypt(data: Data, using context: LCPClientContext) -> Data? {
    return R2LCPClient.decrypt(data: data, using: context as! DRMContext)
  }

  func findOneValidPassphrase(jsonLicense: String, hashedPassphrases: [String]) -> String? {
    return R2LCPClient.findOneValidPassphrase(jsonLicense: jsonLicense, hashedPassphrases: hashedPassphrases)
  }

}

#endif//LCP

