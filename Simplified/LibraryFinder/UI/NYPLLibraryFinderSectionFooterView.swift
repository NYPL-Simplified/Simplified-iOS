//
//  NYPLLibraryFinderSectionFooterView.swift
//  Simplified
//
//  Created by Ernest Fan on 2021-04-28.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import UIKit

class NYPLLibraryFinderSectionFooterView: UICollectionReusableView {
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setupUI()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    // Redraw the border when dark mode activate/deactivate
    updateCustomBorder()
  }
  
  private func setupUI() {
    backgroundColor = NYPLLibraryFinderConfiguration.cellBackgroundColor
    updateCustomBorder()
  }
  
  private func updateCustomBorder() {
    layer.cornerRadius = 6.0
    layer.removeCustomBorders()
    layer.addBorder(side: .notTop,
                    thickness: NYPLLibraryFinderConfiguration.borderWidth,
                    color: NYPLLibraryFinderConfiguration.borderColor.cgColor,
                    maskedCorners: [.layerMinXMaxYCorner, .layerMaxXMaxYCorner])
  }
}
