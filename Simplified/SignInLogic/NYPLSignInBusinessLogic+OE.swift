//
//  NYPLSignInBusinessLogic+OE.swift
//  Open eBooks
//
//  Created by Ettore Pasquini on 10/28/21.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

extension NYPLSignInBusinessLogic {
  @objc func checkCardCreationEligibility(completion: @escaping () -> Void) {
    allowJuvenileCardCreation = false
    completion()
  }

  @objc func makeCardCreatorIfPossible() -> UINavigationController? {
    return nil
  }
}
