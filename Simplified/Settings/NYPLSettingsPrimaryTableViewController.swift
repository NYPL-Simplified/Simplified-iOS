//
//  NYPLSettingsPrimaryTableViewController.swift
//  SimplyE / Open eBooks
//
//  Created by Kyle Sakai.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

class NYPLSettingsPrimaryTableViewController : UITableViewController {
  var items: [NYPLSettingsPrimaryTableItem] {
    didSet {
      itemsMap.removeAll()
      for item in items {
        itemsMap[item.path.section] = max(itemsMap[item.path.section] ?? 0, item.path.row) + 1
      }
      self.tableView.reloadData()
    }
  }
  private var itemsMap: [Int:Int]
  let infoLabel: UILabel
  var shouldShowDeveloperMenuItem: Bool
  var developerVC: NYPLDeveloperSettingsTableViewController
  
  init() {
    self.items = []
    self.itemsMap = [:]
    self.developerVC = NYPLDeveloperSettingsTableViewController()
    self.shouldShowDeveloperMenuItem = false

    // Init info label
    self.infoLabel = UILabel()
    self.infoLabel.font = UIFont.systemFont(ofSize: 12.0)
    let productName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? ""
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? ""
    self.infoLabel.text = "\(productName) version \(version) (\(build))"
    self.infoLabel.textAlignment = .center
    self.infoLabel.sizeToFit()

    super.init(nibName: nil, bundle: nil)
    self.title = NSLocalizedString("Settings", comment: "")
    self.clearsSelectionOnViewWillAppear = false

    // add gesture recognizer for debug menu
    let tap = UITapGestureRecognizer.init(target: self, action: #selector(revealDeveloperSettings))
    tap.numberOfTapsRequired = 7;
    self.infoLabel.isUserInteractionEnabled = true
    self.infoLabel.addGestureRecognizer(tap)
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  var splitVCAncestor: NYPLSettingsSplitViewController? {
    var ancestor = self.parent
    while ancestor != nil {
      guard let splitVC = ancestor as? NYPLSettingsSplitViewController else {
        ancestor = ancestor!.parent
        continue
      }
      return splitVC
    }
    return nil
  }
  
  @objc func revealDeveloperSettings() {
    // Insert a URL to force the field to show.
    self.shouldShowDeveloperMenuItem = true
    self.tableView.reloadData()
  }
  
  func settingsPrimaryTableViewCell(text: String) -> UITableViewCell {
    let cell = UITableViewCell.init(style: .default, reuseIdentifier: nil)
    cell.textLabel?.text = text
    cell.textLabel?.font = UIFont.systemFont(ofSize: 17)
    if self.splitVCAncestor?.traitCollection.horizontalSizeClass == .compact {
      cell.accessoryType = .disclosureIndicator
    } else {
      cell.accessoryType = .none
    }
    return cell
  }
  
  func isDeveloper(path: IndexPath) -> Bool {
    return isDeveloper(section: path.section)
  }
  
  func isDeveloper(section: Int) -> Bool {
    if self.shouldShowDeveloperMenuItem {
      let keys = itemsMap.keys
      let n = keys.count > 0 ? keys.max()! + 1 : 0
      return section == n
    }
    return false
  }
  
  // MARK: UIViewController
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = NYPLConfiguration.backgroundColor()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if self.splitViewController?.traitCollection.horizontalSizeClass == .compact {
      if let indexPath = tableView.indexPathForSelectedRow {
        tableView.deselectRow(at: indexPath, animated: true)
      }
    }
  }
  
  // MARK: UITableViewDelegate
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let splitVC = splitVCAncestor else {
      Log.error("SettingsTableView", "Unable to find split view ancestor")
      return
    }
    
    if isDeveloper(path: indexPath) {
      splitVC.showDetailViewController(NYPLSettingsPrimaryTableItem.handleVCWrap(self.developerVC), sender: self)
    } else {
      for item in self.items {
        if item.path == indexPath {
          item.handleItemTouched(splitVC: splitVC, tableVC: self)
        }
      }
    }
  }
  
  override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    let sectionCount = self.numberOfSections(in: self.tableView)
    if section == sectionCount - 1 {
      return 45.0
    }
    return 0
  }
  
  override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    let sectionCount = self.numberOfSections(in: self.tableView)
    if section == sectionCount - 1 {
      return self.infoLabel
    }
    return UILabel()
  }
  
  // MARK: UITableViewDataSource
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if isDeveloper(path: indexPath) {
      return settingsPrimaryTableViewCell(text: "Testing")
    }
    
    for item in self.items {
      if item.path == indexPath {
        return settingsPrimaryTableViewCell(text: item.name)
      }
    }
    
    return settingsPrimaryTableViewCell(text: "?")
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    let keys = itemsMap.keys
    var n = keys.count > 0 ? keys.max()! + 1 : 0
    if self.shouldShowDeveloperMenuItem {
      n += 1
    }
    return n
  }
  
  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return false
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if self.isDeveloper(section: section) {
      return 1
    }
    return itemsMap[section] ?? 0
  }
}
