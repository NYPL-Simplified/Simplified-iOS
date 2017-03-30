import UIKit
import PureLayout


/// Welcome screen for a first-time user
final class NYPLWelcomeScreenViewController: UIViewController {
  
  var completion: ((Int) -> ())?
  
  required init(completion: ((Int) -> ())?) {
    self.completion = completion
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.view.backgroundColor = NYPLConfiguration.backgroundColor()
    setupViews()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.navigationController?.setNavigationBarHidden(true, animated: false)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.navigationController?.setNavigationBarHidden(false, animated: false)
  }
  
  //MARK -
  
  func setupViews() {
    let view1 = splashScreenView("SplashPickLibraryIcon",
                                 headline: NSLocalizedString("WelcomeScreenTitle1", comment: "Title to tell users they can read books from a library they already have a card for."),
                                 subheadline: NSLocalizedString("WelcomeScreenSubtitle1", comment: "Informs a user of the features of being able to check out a book in the app and even use more than one mobile device"),
                                 buttonTitle: NSLocalizedString("WelcomeScreenButtonTitle1", comment: "Button that lets user know they can select a library they have a card for"),
                                 buttonTargetSelector: #selector(pickYourLibraryTapped))
    
    let view2 = splashScreenView("SplashInstantClassicsIcon",
                                 headline: NSLocalizedString("WelcomeScreenTitle2", comment: "Title to show a user an option if they do not have a library card to check out books."),
                                 subheadline: NSLocalizedString("WelcomeScreenSubtitle2", comment: "Explains what a user can do with the catalog provided. Free books in the public domain."),
                                 buttonTitle: NSLocalizedString("WelcomeScreenButtonTitle2", comment: "Name of section for free books means books that are well-known popular novels for many people."),
                                 buttonTargetSelector: #selector(instantClassicsTapped))
    
    let logoView = UIImageView(image: UIImage(named: "FullLogo"))
    logoView.contentMode = .scaleAspectFit
    
    let containerView = UIView()
    containerView.addSubview(logoView)
    containerView.addSubview(view1)
    containerView.addSubview(view2)
    
    self.view.addSubview(containerView)
    
    logoView.autoPinEdge(toSuperviewMargin: .top)
    logoView.autoAlignAxis(toSuperviewAxis: .vertical)

    view1.autoAlignAxis(toSuperviewAxis: .vertical)
    view1.autoPinEdge(.top, to: .bottom, of: logoView, withOffset: 2)
    view1.autoPinEdge(toSuperviewMargin: .left)
    view1.autoPinEdge(toSuperviewMargin: .right)
    
    view2.autoAlignAxis(toSuperviewAxis: .vertical)
    view2.autoPinEdge(.top, to: .bottom, of: view1, withOffset: 10)
    view2.autoPinEdge(toSuperviewMargin: .left)
    view2.autoPinEdge(toSuperviewMargin: .right)
    
    containerView.autoAlignAxis(toSuperviewAxis: .vertical)
    containerView.autoPinEdge(toSuperviewEdge: .left, withInset: 24, relation: .greaterThanOrEqual)
    containerView.autoPinEdge(toSuperviewEdge: .right, withInset: 24, relation: .greaterThanOrEqual)
    containerView.autoPinEdge(toSuperviewEdge: .top, withInset: 0, relation: .greaterThanOrEqual)
    containerView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 0, relation: .greaterThanOrEqual)
    
    NSLayoutConstraint.autoSetPriority(UILayoutPriorityDefaultHigh) {
      containerView.autoSetDimension(.width, toSize: 350)
      containerView.autoAlignAxis(toSuperviewAxis: .horizontal)
    }
    NSLayoutConstraint.autoSetPriority(UILayoutPriorityDefaultLow) {
      logoView.autoSetDimensions(to: CGSize(width: 180, height: 150))
      view2.autoPinEdge(toSuperviewEdge: .bottom, withInset: 80)
    }
  }
  
  func splashScreenView(_ imageName: String, headline: String, subheadline: String, buttonTitle: String, buttonTargetSelector: Selector) -> UIView {
    let tempView = UIView()
    
    let imageView1 = UIImageView(image: UIImage(named: imageName))
    
    tempView.addSubview(imageView1)
    imageView1.autoSetDimensions(to: CGSize(width: 60, height: 60))
    imageView1.autoAlignAxis(toSuperviewMarginAxis: .vertical)
    imageView1.autoPinEdge(toSuperviewMargin: .top)
    
    let textLabel1 = UILabel()
    textLabel1.numberOfLines = 0
    textLabel1.textAlignment = .center
    textLabel1.text = headline
    textLabel1.font = UIFont.systemFont(ofSize: 20)
    
    tempView.addSubview(textLabel1)
    textLabel1.autoPinEdge(.top, to: .bottom, of: imageView1, withOffset: 2.0, relation: .equal)
    textLabel1.autoPinEdge(.leading, to: .leading, of: tempView, withOffset: 0.0, relation: .greaterThanOrEqual)
    textLabel1.autoPinEdge(.trailing, to: .trailing, of: tempView, withOffset: 0.0, relation: .greaterThanOrEqual)
    textLabel1.autoAlignAxis(toSuperviewMarginAxis: .vertical)
    
    let textLabel2 = UILabel()
    textLabel2.numberOfLines = 0
    textLabel2.textAlignment = .center
    textLabel2.text = subheadline
    textLabel2.font = UIFont.systemFont(ofSize: 16)

    tempView.addSubview(textLabel2)
    textLabel2.autoPinEdge(.top, to: .bottom, of: textLabel1, withOffset: 0.0, relation: .equal)
    textLabel2.autoPinEdge(.leading, to: .leading, of: tempView, withOffset: 0.0, relation: .greaterThanOrEqual)
    textLabel2.autoPinEdge(.trailing, to: .trailing, of: tempView, withOffset: 0.0, relation: .greaterThanOrEqual)
    textLabel2.autoAlignAxis(toSuperviewMarginAxis: .vertical)
    
    let button = UIButton()
    button.setTitle(buttonTitle, for: UIControlState())
    button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
    button.setTitleColor(NYPLConfiguration.iconLogoBlueColor(), for: .normal)
    button.layer.borderColor = NYPLConfiguration.iconLogoGreenColor().cgColor
    button.layer.borderWidth = 2
    button.layer.cornerRadius = 6

    button.contentEdgeInsets = UIEdgeInsetsMake(8.0, 10.0, 8.0, 10.0)
    button.addTarget(self, action: buttonTargetSelector, for: .touchUpInside)
    tempView.addSubview(button)
    
    button.autoPinEdge(.top, to: .bottom, of: textLabel2, withOffset: 8.0, relation: .equal)
    button.autoAlignAxis(toSuperviewMarginAxis: .vertical)
    button.autoPinEdge(toSuperviewMargin: .bottom)
    
    return tempView
  }

  func pickYourLibraryTapped() {
    if completion == nil {
      self.dismiss(animated: true, completion: nil)
      return
    }
    // Existing User
    if NYPLSettings.shared().acceptedEULABeforeMultiLibrary == false {
      let listVC = NYPLWelcomeScreenAccountList { acct in
        if (acct.id != 2) {
          NYPLSettings.shared().settingsAccountsList = [acct.id, 2]
        } else {
          NYPLSettings.shared().settingsAccountsList = [2]
        }
        self.completion?(acct.id)
      }
      self.navigationController?.pushViewController(listVC, animated: true)
    } else {
      let listVC = NYPLWelcomeScreenAccountList { acct in
        if (acct.id != 0 && acct.id != 2) {
          NYPLSettings.shared().settingsAccountsList = [acct.id, 0, 2]
        } else {
          NYPLSettings.shared().settingsAccountsList = [0, 2]
        }
        self.completion?(acct.id)
      }
      self.navigationController?.pushViewController(listVC, animated: true)
    }
  }

  func instantClassicsTapped() {
    if NYPLSettings.shared().acceptedEULABeforeMultiLibrary == true {
      NYPLSettings.shared().settingsAccountsList = [0,2]
    }
    else {
      NYPLSettings.shared().settingsAccountsList = [2]
    }
    completion?(2)
  }
}


/// List of available Libraries/Accounts to select as patron's primary
/// when going through Welcome Screen flow.
final class NYPLWelcomeScreenAccountList: UIViewController, UITableViewDelegate, UITableViewDataSource {
  
  var accounts: [Account]!
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
    self.tableView = self.view as! UITableView
    self.tableView.delegate = self
    self.tableView.dataSource = self
    
    self.accounts = AccountsManager.shared.accounts
    self.title = NSLocalizedString("LibraryListTitle", comment: "Title that also informs the user that they should choose a library from the list.")
    self.view.backgroundColor = NYPLConfiguration.backgroundColor()
  }
  
   func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 100
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    completion(accounts[indexPath.row])
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.accounts.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    return cellForLibrary(self.accounts[indexPath.row])
  }
  
  func cellForLibrary(_ account: Account) -> UITableViewCell {
    let cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "")
    
    cell.textLabel?.font = UIFont.systemFont(ofSize: 18)
    cell.textLabel?.text = account.name
    cell.detailTextLabel?.font = UIFont(name: "AvenirNext-Regular", size: 13)
    cell.detailTextLabel?.text = account.subtitle
    cell.detailTextLabel?.numberOfLines = 3
    if let logo = account.logo
    {
      cell.imageView?.image = UIImage(named: logo)
    }
    else
    {
      cell.imageView?.image = #imageLiteral(resourceName: "LibraryLogoMagic")
    }
    
    return cell
  }
}
