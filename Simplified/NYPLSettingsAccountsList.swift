/// UITableView to display or add library accounts that the user
/// can then log in and adjust settings after selecting Accounts.
class NYPLSettingsAccountsTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

  weak var tableView: UITableView!
  private var allAccountTypes: [Account]
  
  private var accountsList: [NYPLUserAccountType] {
    didSet {
      var array = [Int]()
      for item in accountsList { array.append(item.rawValue) }
      NYPLSettings.sharedSettings().settingsAccountsList = array
      self.updateUI()
    }
  }
  
  private var secondaryAccounts: [NYPLUserAccountType] {
    get {
      var array = [NYPLUserAccountType]()
      for account in self.accountsList {
        if (account.rawValue != self.currentSelectedAccount.rawValue) {
          array.append(account)
        }
      }
      return array
    }
    set {
      var array = newValue
      array.append(self.currentSelectedAccount)
      self.accountsList = array
    }
  }

  private var currentSelectedAccount: NYPLUserAccountType {
    get {
      let currentAccount = NYPLSettings.sharedSettings().currentAccountIdentifier
      guard let account = NYPLUserAccountType(rawValue: currentAccount) else { return NYPLUserAccountType.NYPL }
      return account
    }
  }
  
  required init(accounts: [Int]) {
    var filteredList = [NYPLUserAccountType]()
    for item in accounts {
      guard let library = NYPLUserAccountType(rawValue: item) else { continue }
      filteredList.append(library)
    }
    self.accountsList = filteredList
    self.allAccountTypes = AccountsManager().accounts
    
    super.init(nibName:nil, bundle:nil)
  }
  
  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }

  @available(*, unavailable)
  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: UIViewController
  
  override func loadView() {
    self.view = UITableView(frame: CGRectZero, style: .Grouped)
    self.tableView = self.view as! UITableView
    self.tableView.delegate = self
    self.tableView.dataSource = self
    
    self.title = NSLocalizedString("Accounts",
                                   comment: "A title for a list of libraries the user may select or add to.")
    self.view.backgroundColor = NYPLConfiguration.backgroundColor()
    
    updateUI()
    
    NSNotificationCenter.defaultCenter().addObserver(self,
                                                     selector: #selector(reloadTableView),
                                                     name: NYPLCurrentAccountDidChangeNotification,
                                                     object: nil)
  }
  
  func reloadTableView() {
    self.tableView.reloadData()
  }
  
  func updateUI() {
    if (accountsList.count < self.allAccountTypes.count) {
      self.navigationItem.rightBarButtonItem = UIBarButtonItem(
        barButtonSystemItem: .Add, target: self, action: #selector(addAccount))
    } else {
      self.navigationItem.rightBarButtonItem = nil
    }
  }
  
  func addAccount() {
    let alert = UIAlertController(title: NSLocalizedString(
      "SettingsAccountLibrariesViewControllerAlertTitle",
      comment: "Title to tell a user that they can add another account to the list"),
                                  message: nil,
                                  preferredStyle: .ActionSheet)
    alert.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
    alert.popoverPresentationController?.permittedArrowDirections = .Up
    
    let allAccounts = self.allAccountTypes.map { account in
      return NYPLUserAccountType(rawValue: account.id)
    }
    
    for userAccountType in allAccounts {
      guard let account = userAccountType else { continue }
      if (accountsList.contains(account) == false) {
        alert.addAction(UIAlertAction(title: AccountsManager.account(account.rawValue).name,
          style: .Default,
          handler: { action in
            self.accountsList.append(account)
            self.tableView.reloadData()
        }))
      }
    }

    alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler:nil))
    
    self.presentViewController(alert, animated: true, completion: nil)
  }
  
  // MARK: UITableViewDataSource
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      return 1
    } else if (self.accountsList.count >= 1) {
      return self.accountsList.count - 1
    } else {
      return 0
    }
  }
  
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 2;
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    if (indexPath.section == 0) {
      return cellForLibrary(self.currentSelectedAccount, indexPath)
    } else {
      return cellForLibrary(self.secondaryAccounts[indexPath.row], indexPath)
    }
  }
  
  func cellForLibrary(library: NYPLUserAccountType, _ indexPath: NSIndexPath) -> UITableViewCell {
    let cell = UITableViewCell.init(style: .Subtitle, reuseIdentifier: "")
    
    let account = AccountsManager.account(library.rawValue)
    
    cell.accessoryType = .DisclosureIndicator
    cell.textLabel?.font = UIFont.systemFontOfSize(14)
    cell.textLabel?.text = account.name
    
    cell.detailTextLabel?.font = UIFont(name: "AvenirNext-Regular", size: 12)
    cell.detailTextLabel?.text = account.subtitle
    
    cell.imageView?.image = UIImage(named: account.logo!)

    
    return cell
  }
  
  // MARK: UITableViewDelegate
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    var account: Int
    if (indexPath.section == 0) {
      account = self.currentSelectedAccount.rawValue
    } else {
      account = self.secondaryAccounts[indexPath.row].rawValue
    }
    let viewController = NYPLSettingsAccountDetailViewController(account: account)
    self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
    self.navigationController?.pushViewController(viewController, animated: true)
  }
  
  func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return 60;
  }
  
  func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    if indexPath.section == 0 {
      return false;
    } else {
      return true;
    }
  }
  
  func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if editingStyle == .Delete {
      secondaryAccounts.removeAtIndex(indexPath.row)
      tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
      self.tableView.reloadData()
    }
  }
}
