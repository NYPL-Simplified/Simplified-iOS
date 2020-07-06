//
//  LoginCellTypes.swift
//  SimplyE
//
//  Created by Jacek Szyja on 23/06/2020.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

@objcMembers
class AuthMethodCellType: NSObject {
  let authenticationMethod: AccountDetails.Authentication

  init(authenticationMethod: AccountDetails.Authentication) {
    self.authenticationMethod = authenticationMethod
  }
}

@objcMembers
class InfoHeaderCellType: NSObject {
  let information: String

  init(information: String) {
    self.information = information
  }
}

@objcMembers
class SamlIdpCellType: NSObject {
  let idp: SamlIDP

  init(idp: SamlIDP) {
    self.idp = idp
  }
}

