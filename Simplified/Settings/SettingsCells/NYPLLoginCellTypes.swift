//
//  NYPLLoginCellTypes.swift
//  SimplyE
//
//  Created by Jacek Szyja on 23/06/2020.
//  Copyright © 2020 NYPL. All rights reserved.
//

import Foundation

@objcMembers
class NYPLAuthMethodCellType: NSObject {
  let authenticationMethod: AccountDetails.Authentication

  init(authenticationMethod: AccountDetails.Authentication) {
    self.authenticationMethod = authenticationMethod
  }
}

@objcMembers
class NYPLInfoHeaderCellType: NSObject {
  let information: String

  init(information: String) {
    self.information = information
  }
}

@objcMembers
class NYPLSamlIdpCellType: NSObject {
  let idp: OPDS2SamlIDP

  init(idp: OPDS2SamlIDP) {
    self.idp = idp
  }
}
