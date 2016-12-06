/// UITableView to display or add library accounts that the user
/// can then log in and adjust settings after selecting Accounts.
class NYPLSettingsAccountsTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

  weak var tableView: UITableView!
  private var accounts: [Int] {
    didSet {
      //update NYPLSettings
    }
  }
  private var libraryAccounts: [Account]
  private var userAddedSecondaryAccounts: [Int]!
  private let manager: AccountsManager
  
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
    
    self.userAddedSecondaryAccounts = accounts.filter { $0 != AccountsManager.shared.currentAccount.id }
    
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
    return 2;
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if (indexPath.section == 0) {
      return cellForLibrary(self.manager.currentAccount, indexPath)
    } else {
      return cellForLibrary(AccountsManager.shared.account(userAddedSecondaryAccounts[indexPath.row])!, indexPath)
    }
  }
  
  func cellForLibrary(_ account: Account, _ indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "")
    
    cell.accessoryType = .disclosureIndicator
    cell.textLabel?.font = UIFont.systemFont(ofSize: 14)
    cell.textLabel?.text = account.name
    cell.detailTextLabel?.font = UIFont(name: "AvenirNext-Regular", size: 12)
    cell.detailTextLabel?.text = account.subtitle
    cell.imageView?.image = UIImage(named: account.logo!)
    
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
    return 60;
  }
  
  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    if indexPath.section == 0 {
      return false;
    } else {
      return true;
    }
  }
  
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      userAddedSecondaryAccounts.remove(at: indexPath.row)
      tableView.deleteRows(at: [indexPath], with: .fade)
      updateSettingsAccountList()
      self.tableView.reloadData()
    }
  }
}
