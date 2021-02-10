//
//  LCPPassphraseAuthenticationService.swift
//  Simplified
//
//  Created by Ernest Fan on 2021-02-08.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

#if LCP

import Foundation
import ReadiumLCP

class LCPPassphraseAuthenticationService: LCPAuthenticating {
  func retrievePassphrase(for license: LCPAuthenticatedLicense, reason: LCPAuthenticationReason, allowUserInteraction: Bool, sender: Any?, completion: @escaping (String?) -> Void) {
    guard let hintLink = license.hintLink,
      let hintURL = URL(string: hintLink.href) else {
      Log.error(#file, "LCP Authenticated License does not contain valid hint link")
      completion(nil)
      return
    }
    
    NYPLNetworkExecutor.shared.GET(hintURL) { (result) in
      switch result {
      case .success(let data, _):
        if let json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String:Any],
          let passphrase = json["passphrase"] as? String {
          completion(passphrase)
        } else {
          Log.error(#file, "Error parsing JSON or finding passphrase key/value.")
          completion(nil)
        }
      case .failure(let error, _):
        NYPLErrorLogger.logError(
          withCode: .lcpPassphraseAuthorizationFail,
          summary: "Unable to retrieve LCP passphrase",
          message: "Passphrase retrieval failed to load from \(hintURL)",
          metadata: [
            NSUnderlyingErrorKey: error,
        ])
        completion(nil)
      }
    }
  }
}

#endif
