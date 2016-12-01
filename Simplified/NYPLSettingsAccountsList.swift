/// UITableView to display or add library accounts that the user
/// can then log in and adjust settings after selecting Accounts.
class NYPLSettingsAccountsTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

  weak var tableView: UITableView!
  fileprivate var accounts: [Account]
  
  fileprivate var accountsAdded: [Int] {
    didSet {
      self.updateUI()
    }
  }
  
  fileprivate var secondaryAccounts: [Int] {
    get {
      var array = [Int]()
      for account in self.accountsAdded {
        if (account != self.currentSelectedAccount.id) {
          array.append(account)
        }
      }
      return array
    }
    set {
      var array = newValue
      array.append(self.currentSelectedAccount.id)
      self.accountsAdded = array
    }
  }

  fileprivate var currentSelectedAccount: Account {
    get {
      return AccountsManager.shared.currentAccount
    }
  }
  
  required init(accounts: [Int]) {

    self.accountsAdded = accounts
    self.accounts = AccountsManager.shared.accounts
    
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
    
    self.title = NSLocalizedString("Accounts",
                                   comment: "A title for a list of libraries the user may select or add to.")
    self.view.backgroundColor = NYPLConfiguration.backgroundColor()
    
    updateUI()
    
    NotificationCenter.default.addObserver(self,
                                                     selector: #selector(reloadTableView),
                                                     name: NSNotification.Name(rawValue: NYPLCurrentAccountDidChangeNotification),
                                                     object: nil)
  }
  
  func reloadTableView() {
    self.tableView.reloadData()
  }
  
  func updateUI() {
    if (accountsAdded.count < self.accounts.count) {
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
    
    for userAccount in accounts {
      if (accountsAdded.contains(userAccount.id) == false) {
        alert.addAction(UIAlertAction(title: userAccount.name,
          style: .default,
          handler: { action in
            self.accountsAdded.append(userAccount.id)
            self.tableView.reloadData()
        }))
      }
    }

    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:nil))
    
    self.present(alert, animated: true, completion: nil)
  }
  
  // MARK: UITableViewDataSource
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      return 1
    } else if (self.accountsAdded.count >= 1) {
      return self.accountsAdded.count - 1
    } else {
      return 0
    }
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 2;
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if (indexPath.section == 0) {
      return cellForLibrary(self.currentSelectedAccount, indexPath)
    } else {
      return cellForLibrary(AccountsManager.shared.account(self.secondaryAccounts[indexPath.row])!, indexPath)
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
      account = self.currentSelectedAccount.id
    } else {
      account = self.secondaryAccounts[indexPath.row]
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
      secondaryAccounts.remove(at: indexPath.row)
      tableView.deleteRows(at: [indexPath], with: .fade)
      self.tableView.reloadData()
    }
  }
}
