//
//  LCPAuthenticationService.swift
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
    Log.info(#file, "ENTERing LCP Retrieve Passphrase")
    guard let hintLink = license.hintLink,
      let hintURL = URL(string: hintLink.href) else {
      Log.error(#file, "LCP Authenticated License does not contain valid hint link")
      completion(nil)
      return
    }
    
    NYPLNetworkExecutor.shared.GET(hintURL) { (data, response, error) in
      DispatchQueue.main.async {

        if let error = error as NSError? {
          Log.error(#file, "Request Error Code: \(error.code). Description: \(error.localizedDescription)")
          return
        }
        guard let data = data,
          let response = (response as? HTTPURLResponse) else {
            Log.error(#file, "No Data or No Server Response present after request.")
            return
        }

        if response.statusCode == 200 {
          if let json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String:Any],
            let passphrase = json["passphrase"] as? String {
            completion(passphrase)
            return
          } else {
            Log.error(#file, "Error parsing JSON or finding passphrase key/value.")
          }
        } else {
          Log.error(#file, "Server response returned error code: \(response.statusCode))")
        }
        completion(nil)
      }
    }
    
    Log.info(#file, "Requesting LCP Passphrase - \(hintLink)")
  }
  
  
}

#endif
