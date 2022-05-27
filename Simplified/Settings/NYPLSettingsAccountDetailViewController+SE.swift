//
//  NYPLSettingsAccountDetailViewController+SE.swift
//  Simplified
//
//  Created by Ettore Pasquini on 5/26/22.
//  Copyright © 2022 NYPL. All rights reserved.
//

import Foundation

extension NYPLSettingsAccountDetailViewController {
  @objc func businessLogicDidFinishDeauthorizing(_ businessLogic: NYPLSignInBusinessLogic) {
    removeActivityTitle()
    setupTableData()
  }
}
