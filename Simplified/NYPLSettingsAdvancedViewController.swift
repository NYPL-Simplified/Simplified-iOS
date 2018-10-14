import UIKit

/// Advanced Menu in Settings
@objcMembers class NYPLSettingsAdvancedViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  
  var account: Account

  init(account id: Int) {
    self.account = AccountsManager.shared.account(id)!
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    title = NSLocalizedString("Advanced", comment: "")
    
    let tableView = UITableView.init(frame: .zero, style: .grouped)
    tableView.delegate = self
    tableView.dataSource = self
    tableView.backgroundColor = NYPLConfiguration.backgroundColor()
    self.view.addSubview(tableView)
    tableView.autoPinEdgesToSuperviewEdges()
  }
  
  // MARK: - UITableViewDelegate
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if (indexPath.row == 0) {

      let cell = tableView.cellForRow(at: indexPath)
      cell?.setSelected(false, animated: true)
      
      let message = "Selecting \"Delete\" will remove all bookmarks from the server for \(account.name)."
      let alert = NYPLAlertController.init(title: nil, message: message, preferredStyle: .actionSheet)
      
      let deleteAction = UIAlertAction.init(title: NSLocalizedString("Delete", comment:""), style: .destructive, handler: { (action) in
        self.disableSync()
      })
      
      let cancelAction = UIAlertAction.init(title: NSLocalizedString("Cancel", comment:""), style: .cancel, handler: { (action) in
        Log.debug(#file, "User cancelled bookmark server delete.")
      })
      
      alert.addAction(deleteAction)
      alert.addAction(cancelAction)
      
      alert.present(fromViewControllerOrNil: nil, animated: true, completion: nil)
    }
  }
  
  private func disableSync() {

    //Disable UI while working
    let alert = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)
    let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
    loadingIndicator.hidesWhenStopped = true
    loadingIndicator.style = UIActivityIndicatorView.Style.gray
    loadingIndicator.startAnimating();

    alert.view.addSubview(loadingIndicator)
    present(alert, animated: true, completion: nil)

    NYPLAnnotations.updateServerSyncSetting(toEnabled: false, completion: { success in
      self.dismiss(animated: true, completion: nil)
      if (success) {
        self.account.syncPermissionGranted = false;
        NYPLSettings.shared().userHasSeenFirstTimeSyncMessage = false;
        self.navigationController?.popViewController(animated: true)
      }
    })
  }
  
  // MARK: - UITableViewDataSource
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let cell = UITableViewCell()
    cell.textLabel?.text = NSLocalizedString("Delete Server Data", comment:"")
    cell.textLabel?.font = UIFont.customFont(forTextStyle: .body)
    cell.textLabel?.textColor = .red
    return cell
  }
  
  func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
    return NSLocalizedString("Delete all the bookmarks you have saved in the cloud.", comment:"")
  }

}
