//
//  NYPLSamlIDPCell.swift
//  SimplyE
//
//  Created by Jacek Szyja on 29/06/2020.
//  Copyright © 2020 NYPL. All rights reserved.
//

import UIKit

@objcMembers
class NYPLSamlIDPCell: UITableViewCell {

  let idpName: UILabel = {
    let label = UILabel()
    label.textAlignment = .right
    label.font =  UIFont.customFont(forTextStyle: .subheadline)
    label.textColor = UIColor.systemBlue
    return label
  }()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)

    idpName.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(idpName)

    idpName.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
    idpName.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
    idpName.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: -32).isActive = true
    idpName.heightAnchor.constraint(equalTo: contentView.heightAnchor, constant: -16).isActive = true
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
