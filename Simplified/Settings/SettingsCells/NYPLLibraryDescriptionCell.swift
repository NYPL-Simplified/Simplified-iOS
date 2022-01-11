//
//  NYPLLibraryDescriptionCell.swift
//  SimplyE
//
//  Created by Jacek Szyja on 29/06/2020.
//  Copyright © 2020 NYPL. All rights reserved.
//

import UIKit

@objcMembers
class NYPLLibraryDescriptionCell: UITableViewCell {

  let descriptionLabel: UILabel = {
    let label = UILabel()
    label.numberOfLines = 0
    label.font =  UIFont(name: "AvenirNext-Regular", size: 12)
    return label
  }()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)

    descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(descriptionLabel)

    descriptionLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
    descriptionLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
    descriptionLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: -32).isActive = true
    descriptionLabel.heightAnchor.constraint(equalTo: contentView.heightAnchor, constant: -16).isActive = true
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
