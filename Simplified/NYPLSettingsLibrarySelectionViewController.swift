/// Type of library that can be added by the user
/// to log in witih.
@objc enum NYPLChosenLibrary: Int {
  case NYPL = 0
  case Brooklyn
  case Magic
  
  func simpleDescription() -> String {
    switch self {
    case .NYPL:
      return "New York Public Library"
    case .Brooklyn:
      return "Brooklyn Public Library"
    case .Magic:
      return "The Magic Library"
    }
  }
}

/// UITableView to display or add libraries that the user
/// can then log in to after selecting Accounts.
class NYPLSettingsLibrarySelectionViewControlelr: UIViewController, UITableViewDelegate, UITableViewDataSource {
  
  private var libraryList: [NYPLChosenLibrary] {
    didSet {
      var array = [Int]()
      for item in libraryList { array.append(item.rawValue) }
      NYPLSettings.sharedSettings().libraryAccounts = array
    }
  }
  
  weak var tableView: UITableView!
  
  required init(libraries: [Int]) {
    self.libraryList = []
    for item in libraries {
      guard let library = NYPLChosenLibrary(rawValue: item) else { continue }
      self.libraryList.append(library)
    }
    super.init(nibName:nil, bundle:nil)
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
    
    self.title = "Libraries"
    self.view.backgroundColor = NYPLConfiguration.backgroundColor()
    
    updateUI()
  }
  
  func updateUI() {
    if (libraryList.count < 3) {
      self.navigationItem.rightBarButtonItem = UIBarButtonItem(
        barButtonSystemItem: .Add, target: self, action: #selector(addLibrary))
    } else {
      self.navigationItem.rightBarButtonItem = nil
    }
  }
  
  func addLibrary() {
    let alert = UIAlertController(title: "Add Your Library", message: nil, preferredStyle: .ActionSheet)
    alert.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
    alert.popoverPresentationController?.permittedArrowDirections = .Up
    
    //need to improve way to check for which to show
    
    if (libraryList.contains(.NYPL) == false) {
      alert.addAction(UIAlertAction(title: "New York Public Library", style: .Default, handler: { action in
        self.libraryList.append(NYPLChosenLibrary.NYPL)
        self.tableView.reloadData()
        self.updateUI()
      }))
    }
    
    if (libraryList.contains(.Brooklyn) == false) {
      alert.addAction(UIAlertAction(title: "Brooklyn Public Library", style: .Default, handler: { action in
        self.libraryList.append(NYPLChosenLibrary.Brooklyn)
        self.tableView.reloadData()
        self.updateUI()
      }))
    }
    
    if (libraryList.contains(.Magic) == false) {
      alert.addAction(UIAlertAction(title: "The Magic Library", style: .Default, handler: { action in
        self.libraryList.append(NYPLChosenLibrary.Magic)
        self.tableView.reloadData()
        self.updateUI()
      }))
    }
    
    alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler:nil))
    
    self.presentViewController(alert, animated: true, completion: nil)
  }
  
  // MARK: UITableViewDataSource
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.libraryList.count
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = UITableViewCell.init(style: .Subtitle, reuseIdentifier: "")
    cell.accessoryType = .DisclosureIndicator
    cell.textLabel?.font = UIFont(name: "AvenirNext-Regular", size: 14)
    cell.textLabel?.text = libraryList[indexPath.row].simpleDescription()
    cell.detailTextLabel?.font = UIFont(name: "AvenirNext-Regular", size: 10)
    cell.detailTextLabel?.text = "Subtitle will go here."
    cell.imageView?.image = UIImage(named: "Catalog")
    
    return cell
  }
  
  // MARK: UITableViewDelegate
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    //LOAD ACCOUNT VIEW CONTROLLER WITH LIBRARY: NYPLChosenLibrary.rawValue
    //for now just navigating to sign in controller
    let viewController = NYPLSettingsAccountViewController()
    self.navigationController?.pushViewController(viewController, animated: true)
    //show detail is not working on iphone, still need to fix
//    self.showDetailViewController(viewController, sender: self)
  }
  
  func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return 60;
  }
  
  func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    if self.libraryList.count <= 1 {
      return false;
    } else {
      return true;
    }
  }
  
  func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if editingStyle == .Delete {
      self.libraryList.removeAtIndex(indexPath.row)
      tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
      updateUI()
    }
  }
}
