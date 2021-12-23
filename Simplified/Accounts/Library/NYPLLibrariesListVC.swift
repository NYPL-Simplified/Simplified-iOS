//
//  NYPLLibrariesListVC.swift
//
//  Created by Greg O'Neill on 11/10/2016.
//  Copyright © 2016 NYPL Labs. All rights reserved.
//

import Foundation

/// Lists all the available libraries from the library registry in a table view.
final class NYPLLibrariesListVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

  var accounts: [Account]!
  var nyplAccounts: [Account]!
  let completion: (Account) -> ()
  weak var tableView : UITableView!

  required init(completion: @escaping (Account) -> ()) {
    self.completion = completion
    super.init(nibName:nil, bundle:nil)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    self.view = UITableView(frame: .zero, style: .grouped)
    self.tableView = self.view as? UITableView
    self.tableView.delegate = self
    self.tableView.dataSource = self

    self.accounts = AccountsManager.shared.accounts()

    //FIXME Replace with SettingsAccounts improvements to library selection VC
    //once that gets finalized and merged in.
    self.accounts.sort { $0.name < $1.name }
    self.nyplAccounts = self.accounts.filter { AccountsManager.NYPLAccountUUIDs.contains($0.uuid) }
    self.accounts = self.accounts.filter { !AccountsManager.NYPLAccountUUIDs.contains($0.uuid) }

    self.title = NSLocalizedString("Pick Your Library", comment: "Title that also informs the user that they should choose a library from the list.")
    self.view.backgroundColor = NYPLConfiguration.primaryBackgroundColor
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 100
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.section == 0 {
      completion(nyplAccounts[indexPath.row])
    } else {
      completion(accounts[indexPath.row])
    }
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      return self.nyplAccounts.count
    } else {
      return self.accounts.count
    }
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.section == 0 {
      return cellForLibrary(self.nyplAccounts[indexPath.row])
    } else {
      return cellForLibrary(self.accounts[indexPath.row])
    }
  }

  func cellForLibrary(_ account: Account) -> UITableViewCell {
    let cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "")

    let container = UIView()
    let textContainer = UIView()

    cell.accessoryType = .disclosureIndicator
    let imageView = UIImageView(image: account.logo)
    imageView.contentMode = .scaleAspectFit

    let textLabel = UILabel()
    textLabel.font = UIFont.systemFont(ofSize: 16)
    textLabel.text = account.name
    textLabel.numberOfLines = 0

    let detailLabel = UILabel()
    detailLabel.font = UIFont(name: "AvenirNext-Regular", size: 12)
    detailLabel.numberOfLines = 0
    detailLabel.text = account.subtitle

    textContainer.addSubview(textLabel)
    textContainer.addSubview(detailLabel)

    container.addSubview(imageView)
    container.addSubview(textContainer)
    cell.contentView.addSubview(container)

    imageView.autoAlignAxis(toSuperviewAxis: .horizontal)
    imageView.autoPinEdge(toSuperviewEdge: .left)
    imageView.autoSetDimensions(to: CGSize(width: 45, height: 45))

    textContainer.autoPinEdge(.left, to: .right, of: imageView, withOffset: cell.contentView.layoutMargins.left * 2)
    textContainer.autoPinEdge(toSuperviewMargin: .right)
    textContainer.autoAlignAxis(toSuperviewAxis: .horizontal)

    NSLayoutConstraint.autoSetPriority(UILayoutPriority.defaultLow) {
      textContainer.autoPinEdge(toSuperviewEdge: .top, withInset: 0, relation: .greaterThanOrEqual)
      textContainer.autoPinEdge(toSuperviewEdge: .bottom, withInset: 0, relation: .greaterThanOrEqual)
    }

    textLabel.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)

    detailLabel.autoPinEdge(.top, to: .bottom, of: textLabel)
    detailLabel.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)

    container.autoPinEdgesToSuperviewMargins()
    container.autoSetDimension(.height, toSize: 55, relation: .greaterThanOrEqual)

    return cell
  }
}
