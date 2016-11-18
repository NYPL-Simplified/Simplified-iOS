import Foundation

/// List of available Libraries/Accounts to select as patron's primary
/// when going through Welcome Screen flow.
final class NYPLWelcomeScreenAccountList: UITableViewController {
  
  var accounts: [Account]!
  let completion: Account -> ()
  
  required init(completion: Account -> ()) {
    self.completion = completion
    super.init(nibName: nil, bundle: nil)
  }
  
  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    self.accounts = Accounts().accounts
    
    self.navigationItem.hidesBackButton = true
    self.title = "Pick Your Library"
  }
  
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    completion(accounts[indexPath.row])
  }

  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.accounts.count
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    var cell = tableView.dequeueReusableCellWithIdentifier("cellID") as UITableViewCell!
    if (cell == nil) {
      cell = UITableViewCell(style:.Default, reuseIdentifier:"cellID")
    }
    cell.textLabel!.text = self.accounts[indexPath.row].name
    return cell
  }

}