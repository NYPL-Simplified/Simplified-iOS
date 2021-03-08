//
//  NYPLAccountSignInViewController+OESelectAuth.swift
//  Simplified
//
//  Created by Ettore Pasquini on 10/8/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

enum LoginChoice {
  case firstBook, clever
}

extension NYPLAccountSignInViewController {
  convenience init(loginChoice: LoginChoice) {
    self.init()
    self.businessLogic.selectAuthentication(forLoginChoice: loginChoice)
  }
}

extension NYPLSignInBusinessLogic {
  fileprivate func selectAuthentication(forLoginChoice loginChoice: LoginChoice) {
    guard let authentications = libraryAccount?.details?.auths else {
      return
    }

    let matches = authentications.filter {
      switch loginChoice {
      case .firstBook:
        return $0.authType == .basic
      case .clever:
        return $0.authType == .oauthIntermediary
      }
    }

    selectedAuthentication = matches.first
  }
}
