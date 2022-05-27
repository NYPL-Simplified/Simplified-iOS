//
//  NYPLSettingsAccountDetailViewController+OE.swift
//  Open eBooks
//
//  Created by Ettore Pasquini on 5/26/22.
//  Copyright © 2022 NYPL. All rights reserved.
//

import UIKit

extension NYPLSettingsAccountDetailViewController {
  @objc func businessLogicDidFinishDeauthorizing(_ businessLogic: NYPLSignInBusinessLogic) {
    (UIApplication.shared.delegate as? NYPLAppDelegate)?.setUpRootVC()
  }
}
