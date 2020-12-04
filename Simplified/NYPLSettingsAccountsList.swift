/// UITableView to display or add library accounts that the user
/// can then log in and adjust settings after selecting Accounts.
@objcMembers class NYPLSettingsAccountsTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

  enum LoadState {
    case loading
    case failure
    case success
  }

  weak var tableView: UITableView!
  var reloadView: NYPLReloadView!
  var spinner: UIActivityIndicatorView!

  fileprivate var accounts: [String] {
    didSet {
      //update NYPLSettings
    }
  }
  fileprivate var libraryAccounts: [Account]
  fileprivate var userAddedSecondaryAccounts: [String]!
  fileprivate let manager: AccountsManager
  
  required init(accounts: [String]) {
    self.accounts = accounts
    self.manager = AccountsManager.shared
    self.libraryAccounts = manager.accounts()

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
    self.tableView = self.view as? UITableView
    self.tableView.delegate = self
    self.tableView.dataSource = self

    spinner = UIActivityIndicatorView(style: .gray)
    view.addSubview(spinner)

    reloadView = NYPLReloadView()
    reloadView.handler = { [weak self] in
      guard let self = self else {
        return
      }
      self.reloadAccounts()
    }
    view.addSubview(reloadView)

    // cleanup accounts, remove demo account or accounts not supported through accounts.json // will be refactored when implementing librsry registry
    var accountsToRemove = [String]()
    
    for account in accounts {
      if (AccountsManager.shared.account(account) == nil) {
        accountsToRemove.append(account)
      }
    }

    for remove in accountsToRemove {
      if let index = accounts.index(of: remove) {
        accounts.remove(at: index)
      }
    }
    
    self.userAddedSecondaryAccounts = accounts.filter { $0 != AccountsManager.shared.currentAccount?.uuid }
    
    updateSettingsAccountList()

    self.title = NSLocalizedString("Accounts",
                                   comment: "A title for a list of libraries the user may select or add to.")
    self.view.backgroundColor = NYPLConfiguration.backgroundColor()
    self.navigationItem.rightBarButtonItem =
      UIBarButtonItem(title: NSLocalizedString("Add Library", comment: "Title of button to add a new library"),
                      style: .plain,
                      target: self,
                      action: #selector(addAccount))
    
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(reloadAfterAccountChange),
                                           name: NSNotification.Name.NYPLCurrentAccountDidChange,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(catalogChangeHandler),
                                           name: NSNotification.Name.NYPLCatalogDidLoad,
                                           object: nil)

    self.libraryAccounts = manager.accounts()
    updateNavBar()
  }

  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    spinner.centerInSuperview(withOffset: tableView.contentOffset)
    reloadView.centerInSuperview(withOffset: tableView.contentOffset)
  }

  // MARK: -

  func showLoadingUI(loadState: LoadState) {
    switch loadState {
    case .loading:
      spinner.isHidden = false
      spinner.startAnimating()
      reloadView.isHidden = true
      view.bringSubviewToFront(spinner)
    case .failure:
      spinner.stopAnimating()
      reloadView.isHidden = false
      view.bringSubviewToFront(reloadView)
    case .success:
      spinner.stopAnimating()
      reloadView.isHidden = true
    }
  }

  func reloadAccounts() {
    showLoadingUI(loadState: .loading)

    manager.updateAccountSet { [weak self] success in
      NYPLMainThreadRun.asyncIfNeeded { [weak self] in
        guard let self = self else {
          return
        }
        if success {
          self.showLoadingUI(loadState: .success)
        } else {
          self.showLoadingUI(loadState: .failure)
          NYPLErrorLogger.logError(withCode: .apiCall,
                                   summary: "NYPLSettingsAccountsList",
                                   message: "Accounts list failed to load",
                                   metadata: [
                                    "currentLibrary": self.manager.currentAccount?.debugDescription ?? "N/A"])
        }
      }
    }
  }

  func reloadAfterAccountChange() {
    accounts = NYPLSettings.shared.settingsAccountsList
    self.userAddedSecondaryAccounts = accounts.filter { $0 != manager.currentAccount?.uuid }
    DispatchQueue.main.async {
      self.tableView.reloadData()
    }
  }
  
  func catalogChangeHandler() {
    self.libraryAccounts = AccountsManager.shared.accounts()
    DispatchQueue.main.async {
      self.updateNavBar()
    }
  }
  
  private func updateNavBar() {
    let enable = self.userAddedSecondaryAccounts.count + 1 < self.libraryAccounts.count
    self.navigationItem.rightBarButtonItem?.isEnabled = enable
  }

  @objc private func addAccount() {
    AccountsManager.shared.loadCatalogs() { success in
      DispatchQueue.main.async {
        guard success else {
          let alert = NYPLAlertUtils.alert(title:nil, message:"We can’t get your library right now. Please close and reopen the app to try again.", style: .cancel)
          NYPLAlertUtils.presentFromViewControllerOrNil(alertController: alert, viewController: self, animated: true, completion: nil)
          return
        }
        self.libraryAccounts = AccountsManager.shared.accounts()
        self.showAddAccountList()
      }
    }
  }
  
  private func showAddAccountList() {
    let alert = UIAlertController(title: NSLocalizedString(
      "Add Your Library",
      comment: "Title to tell a user that they can add another account to the list"),
                                  message: nil,
                                  preferredStyle: .actionSheet)
    alert.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
    alert.popoverPresentationController?.permittedArrowDirections = .up

    let sortedLibraryAccounts = self.libraryAccounts.sorted { (a, b) in
      // Check if we're one of the three "special" libraries that always come first.
      // This is a complete hack.
      let idA = AccountsManager.NYPLAccountUUIDs.firstIndex(of: a.uuid) ?? Int.max
      let idB = AccountsManager.NYPLAccountUUIDs.firstIndex(of: b.uuid) ?? Int.max
      if idA <= 2 || idB <= 2 {
        // One of the libraries is special, so sort it first. Lower ids are "more
        // special" than higher ids and thus show up earlier.
        return idA < idB
      } else {
        // Neither library is special so we just go alphabetically.
        return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
      }
    }

    for userAccount in sortedLibraryAccounts {
      if (!userAddedSecondaryAccounts.contains(userAccount.uuid) && userAccount.uuid != manager.currentAccount?.uuid) {
        alert.addAction(UIAlertAction(title: userAccount.name,
          style: .default,
          handler: { action in
            self.userAddedSecondaryAccounts.append(userAccount.uuid)
            self.updateSettingsAccountList()
            self.updateNavBar()
            self.tableView.reloadData()
        }))
      }
    }

    alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button title"), style: .cancel, handler:nil))
    
    self.present(alert, animated: true, completion: nil)
  }
  
  private func updateSettingsAccountList() {
    guard let uuid = manager.currentAccount?.uuid else {
      showLoadingUI(loadState: .failure)
      return
    }
    showLoadingUI(loadState: .success)
    var array = userAddedSecondaryAccounts!
    array.append(uuid)
    NYPLSettings.shared.settingsAccountsList = array
  }
  
  // MARK: UITableViewDataSource
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let numRows: Int
    if section == 0 {
      numRows = self.manager.currentAccount != nil ? 1 : 0
    } else {
      numRows = userAddedSecondaryAccounts.count
    }

    return numRows
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if (indexPath.section == 0) {
      guard let account = self.manager.currentAccount else {
        // Should never happen, but better than crashing
        return UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "cell")
      }
      return cellForLibrary(account, indexPath)
    } else {
      return cellForLibrary(AccountsManager.shared.account(userAddedSecondaryAccounts[indexPath.row])!, indexPath)
    }
  }
  
  func cellForLibrary(_ account: Account, _ indexPath: IndexPath) -> UITableViewCell {

    let cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "cell")

    let container = UIView()
    let textContainer = UIView()
    
    cell.accessoryType = .disclosureIndicator
    let imageView = UIImageView(image: account.logo)
    imageView.contentMode = .scaleAspectFit
    
    let textLabel = UILabel()
    textLabel.font = UIFont.systemFont(ofSize: 14)
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

    textContainer.autoPinEdge(.left, to: .right, of: imageView, withOffset: cell.contentView.layoutMargins.left)
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
  
  // MARK: UITableViewDelegate
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    var account: String
    if (indexPath.section == 0) {
      account = self.manager.currentAccount?.uuid ?? ""
    } else {
      account = userAddedSecondaryAccounts[indexPath.row]
    }
    let vc = NYPLSettingsAccountDetailViewController(libraryAccountID: account)
    self.tableView.deselectRow(at: indexPath, animated: true)
    self.navigationController?.pushViewController(vc, animated: true)
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return UITableView.automaticDimension
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
  
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      userAddedSecondaryAccounts.remove(at: indexPath.row)
      tableView.deleteRows(at: [indexPath], with: .fade)
      updateSettingsAccountList()
      updateNavBar()
      self.tableView.reloadData()
    }
  }
}
