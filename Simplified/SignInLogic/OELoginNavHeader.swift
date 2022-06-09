//
//  OELoginNavHeader.swift
//  Open eBooks
//
//  Created by Ettore Pasquini on 6/7/22.
//  Copyright © 2022 NYPL. All rights reserved.
//

import UIKit
import PureLayout

class OELoginNavHeader: UIView {
  @IBOutlet var logoImageView: UIImageView!
  @IBOutlet var logoTextImageView: UIImageView!
  @IBOutlet var container: UIView!

  convenience init() {
    self.init(frame: .zero)
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setUpView()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setUpView()
  }

  private func setUpView() {
    let nib = UINib(nibName: String(describing: type(of: self)), bundle: nil)
    guard nib.instantiate(withOwner: self).first != nil else {
      return
    }

    addSubview(container)
    container.autoCenterInSuperview()
  }
}
