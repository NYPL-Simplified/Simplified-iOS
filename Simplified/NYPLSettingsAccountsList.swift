/// UITableView to display or add library accounts that the user
/// can then log in and adjust settings after selecting Accounts.
class NYPLSettingsAccountsTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

  weak var tableView: UITableView!
  fileprivate var accounts: [Int] {
    didSet {
      //update NYPLSettings
    }
  }
  fileprivate var libraryAccounts: [Account]
  fileprivate var userAddedSecondaryAccounts: [Int]!
  fileprivate let manager: AccountsManager
  
  required init(accounts: [Int]) {
    self.accounts = accounts
    self.manager = AccountsManager.shared
    self.libraryAccounts = manager.accounts

    super.init(nibName:nil, bundle:nil)
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  @available(*, unavailable)
  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: UIViewController
  
  override func loadView() {
    self.view = UITableView(frame: CGRect.zero, style: .grouped)
    self.tableView = self.view as! UITableView
    self.tableView.delegate = self
    self.tableView.dataSource = self
    
    
    // cleanup accounts, remove demo account or accounts not supported through accounts.json // will be refactored when implementing librsry registry
    var accountsToRemove = [Int]()
    
    for account in accounts
    {
      if (AccountsManager.shared.account(account) == nil)
      {
        accountsToRemove.append(account)
      }
    }

    for remove in accountsToRemove
    {
      if let index = accounts.index(of: remove) {
        accounts.remove(at: index)
      }

    }
    
    self.userAddedSecondaryAccounts = accounts.filter { $0 != AccountsManager.shared.currentAccount.id }
    
    updateSettingsAccountList()

    self.title = NSLocalizedString("Accounts",
                                   comment: "A title for a list of libraries the user may select or add to.")
    self.view.backgroundColor = NYPLConfiguration.backgroundColor()
    
    updateUI()
    
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(reloadAfterAccountChange),
                                           name: NSNotification.Name(rawValue: NYPLCurrentAccountDidChangeNotification),
                                           object: nil)
  }
  
  func reloadAfterAccountChange() {
    accounts = NYPLSettings.shared().settingsAccountsList as! [Int]
    self.userAddedSecondaryAccounts = accounts.filter { $0 != manager.currentAccount.id }
    self.tableView.reloadData()
  }
  
  func updateUI() {
    if (userAddedSecondaryAccounts.count + 1 < libraryAccounts.count) {
      self.navigationItem.rightBarButtonItem = UIBarButtonItem(
        barButtonSystemItem: .add, target: self, action: #selector(addAccount))
    } else {
      self.navigationItem.rightBarButtonItem = nil
    }
  }
  
  func addAccount() {
    let alert = UIAlertController(title: NSLocalizedString(
      "SettingsAccountLibrariesViewControllerAlertTitle",
      comment: "Title to tell a user that they can add another account to the list"),
                                  message: nil,
                                  preferredStyle: .actionSheet)
    alert.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
    alert.popoverPresentationController?.permittedArrowDirections = .up
    
    for userAccount in libraryAccounts {
      if (!userAddedSecondaryAccounts.contains(userAccount.id) && userAccount.id != manager.currentAccount.id) {
        alert.addAction(UIAlertAction(title: userAccount.name,
          style: .default,
          handler: { action in
            self.userAddedSecondaryAccounts.append(userAccount.id)
            self.updateSettingsAccountList()
            self.updateUI()
            self.tableView.reloadData()
        }))
      }
    }

    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:nil))
    
    self.present(alert, animated: true, completion: nil)
  }
  
  func updateSettingsAccountList() {
    var array = userAddedSecondaryAccounts!
    array.append(manager.currentAccount.id)
    NYPLSettings.shared().settingsAccountsList = array
  }
  
  // MARK: UITableViewDataSource
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      return 1
    } else {
      return userAddedSecondaryAccounts.count
    }
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if (indexPath.section == 0) {
      return cellForLibrary(self.manager.currentAccount, indexPath)
    } else {
      return cellForLibrary(AccountsManager.shared.account(userAddedSecondaryAccounts[indexPath.row])!, indexPath)
    }
  }
  
  func cellForLibrary(_ account: Account, _ indexPath: IndexPath) -> UITableViewCell {

    let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "cell")
    
    
    let container = UIView()
    
    cell.accessoryType = .disclosureIndicator
    
    var imageView = UIImageView(image: UIImage(named: account.logo!))
    
    if let logo = account.logo
    {
      imageView = UIImageView(image: UIImage(named: logo))
    }
    else
    {
      imageView = UIImageView(image: #imageLiteral(resourceName: "LibraryLogoMagic"))
    }
    
    imageView.contentMode = .center
    
    let textLabel = UILabel()
    textLabel.font = UIFont.systemFont(ofSize: 14)
    textLabel.text = account.name
    textLabel.numberOfLines = 0

    let detailLabel = UILabel()
    detailLabel.font = UIFont(name: "AvenirNext-Regular", size: 12)
    detailLabel.numberOfLines = 0
    detailLabel.text = account.subtitle
    
    container.addSubview(imageView)
    container.addSubview(textLabel)
    container.addSubview(detailLabel)
    cell.contentView.addSubview(container)
    
    imageView.autoAlignAxis(toSuperviewAxis: .horizontal)
    imageView.autoPinEdge(toSuperviewEdge: .left)
    imageView.autoSetDimensions(to: CGSize(width: 45, height: 45))
    
    textLabel.autoPinEdge(toSuperviewEdge: .top)
    textLabel.autoPinEdge(.bottom, to: .top, of: detailLabel)
    textLabel.autoPinEdge(.left, to: .right, of: imageView, withOffset: cell.contentView.layoutMargins.left)
    textLabel.autoPinEdge(toSuperviewEdge: .right)
    
    detailLabel.autoPinEdge(.top, to: .bottom, of: textLabel)
    detailLabel.autoPinEdge(toSuperviewEdge: .bottom)
    detailLabel.autoPinEdge(.left, to: .left, of: textLabel)
    detailLabel.autoPinEdge(toSuperviewEdge: .right)
    
    container.autoPinEdgesToSuperviewMargins()
    
    return cell
  }
  
  // MARK: UITableViewDelegate
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    var account: Int
    if (indexPath.section == 0) {
      account = self.manager.currentAccount.id
    } else {
      account = userAddedSecondaryAccounts[indexPath.row]
    }
    let viewController = NYPLSettingsAccountDetailViewController(account: account)
    self.tableView.deselectRow(at: indexPath, animated: true)
    self.navigationController?.pushViewController(viewController!, animated: true)
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return UITableViewAutomaticDimension
  }
  
  func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
    return 80
  }
  
  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    if indexPath.section == 0 {
      return false
    } else {
      return true
    }
  }
  
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      userAddedSecondaryAccounts.remove(at: indexPath.row)
      tableView.deleteRows(at: [indexPath], with: .fade)
      updateSettingsAccountList()
      updateUI()
      self.tableView.reloadData()
    }
  }
}
