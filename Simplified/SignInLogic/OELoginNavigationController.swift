//
//  OELoginNavigationController.swift
//  Open eBooks
//
//  Created by Ettore Pasquini on 6/6/22.
//  Copyright © 2022 NYPL. All rights reserved.
//

import Foundation
import UIKit
import PureLayout

class OELoginNavigationController: UINavigationController {
  init() {
    let choiceVC = OELoginChoiceViewController()
    super.init(rootViewController: choiceVC)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
