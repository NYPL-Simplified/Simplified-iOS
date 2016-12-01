import UIKit
import PureLayout


/// Welcome screen for a first-time user
final class NYPLWelcomeScreenViewController: UIViewController {
  
  var completion: (() -> ())?
  
  required init(completion: (() -> ())?) {
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
    
    logoView.autoPinEdge(toSuperviewMargin: .top)
    logoView.autoAlignAxis(toSuperviewAxis: .vertical)
    logoView.autoSetDimensions(to: CGSize(width: 180, height: 150))
    
    view1.autoAlignAxis(toSuperviewAxis: .vertical)
    view1.autoPinEdge(.top, to: .bottom, of: logoView, withOffset: 5)
    
    view2.autoAlignAxis(toSuperviewAxis: .vertical)
    view2.autoPinEdge(.top, to: .bottom, of: view1, withOffset: 8)
    view2.autoPinEdge(toSuperviewEdge: .bottom, withInset: 80)
    view2.autoPinEdge(toSuperviewMargin: .left)
    view2.autoPinEdge(toSuperviewMargin: .right)
    
    
    self.view.addSubview(containerView)
    containerView.autoCenterInSuperview()
  }
  
  func splashScreenView(_ imageName: String, headline: String, subheadline: String, buttonTitle: String, buttonTargetSelector: Selector) -> UIView {
    let tempView = UIView()
    
    let imageView1 = UIImageView(image: UIImage(named: imageName))
    
    tempView.addSubview(imageView1)
    imageView1.autoSetDimensions(to: CGSize(width: 60, height: 60))
    imageView1.autoAlignAxis(toSuperviewMarginAxis: .vertical)
    imageView1.autoPinEdge(toSuperviewMargin: .top)
    
    let textLabel1 = UILabel()
    textLabel1.textAlignment = .center
    textLabel1.text = headline
    textLabel1.font = UIFont.systemFont(ofSize: 16)
    
    tempView.addSubview(textLabel1)
    textLabel1.autoPinEdge(.top, to: .bottom, of: imageView1, withOffset: 2.0, relation: .equal)
    textLabel1.autoPinEdge(.leading, to: .leading, of: tempView, withOffset: 0.0, relation: .greaterThanOrEqual)
    textLabel1.autoPinEdge(.trailing, to: .trailing, of: tempView, withOffset: 0.0, relation: .greaterThanOrEqual)
    textLabel1.autoAlignAxis(toSuperviewMarginAxis: .vertical)
    
    let textLabel2 = UILabel()
    textLabel2.textAlignment = .center
    textLabel2.text = subheadline
    textLabel2.font = UIFont.systemFont(ofSize: 12)

    tempView.addSubview(textLabel2)
    textLabel2.autoPinEdge(.top, to: .bottom, of: textLabel1, withOffset: 0.0, relation: .equal)
    textLabel2.autoPinEdge(.leading, to: .leading, of: tempView, withOffset: 0.0, relation: .greaterThanOrEqual)
    textLabel2.autoPinEdge(.trailing, to: .trailing, of: tempView, withOffset: 0.0, relation: .greaterThanOrEqual)
    textLabel2.autoAlignAxis(toSuperviewMarginAxis: .vertical)
    
    let button = UIButton()
    button.setTitle(buttonTitle, for: UIControlState())
    button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
    button.setTitleColor(UIColor.init(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0), for: UIControlState())
    button.layer.borderColor = UIColor.init(red: 141.0/255.0, green: 199.0/255.0, blue: 64.0/255.0, alpha: 1.0).cgColor
    button.layer.borderWidth = 2
    button.layer.cornerRadius = 6

    button.contentEdgeInsets = UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0)
    button.addTarget(self, action: buttonTargetSelector, for: .touchUpInside)
    tempView.addSubview(button)
    
    button.autoPinEdge(.top, to: .bottom, of: textLabel2, withOffset: 6.0, relation: .equal)
    button.autoAlignAxis(toSuperviewMarginAxis: .vertical)
    button.autoPinEdge(toSuperviewMargin: .bottom)
    
    return tempView
  }

  func pickYourLibraryTapped() {
    if completion == nil {
      self.dismiss(animated: true, completion: nil)
      return
    }
    let accountNYPL = AccountsManager.shared.account(0)!
    // Existing User
    if accountNYPL.eulaIsAccepted == false {
      let listVC = NYPLWelcomeScreenAccountList { libraryAccount in
        NYPLSettings.shared().currentAccountIdentifier = libraryAccount.id
        self.completion!()
      }
      self.navigationController?.pushViewController(listVC, animated: true)
    } else {
      completion!()
    }
  }
  
  func instantClassicsTapped() {
    AccountsManager.shared.changeCurrentAccount(identifier: 2)
    if completion != nil {
      completion!()
    }
  }
}


/// List of available Libraries/Accounts to select as patron's primary
/// when going through Welcome Screen flow.
final class NYPLWelcomeScreenAccountList: UITableViewController {
  
  var accounts: [Account]!
  let completion: (Account) -> ()
  
  required init(completion: @escaping (Account) -> ()) {
    self.completion = completion
    super.init(style: .grouped)
  }
  
  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    self.accounts = AccountsManager.shared.accounts
    self.title = NSLocalizedString("LibraryListTitle", comment: "Title that also informs the user that they should choose a library from the list.")
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    completion(accounts[indexPath.row])
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.accounts.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    var cell = tableView.dequeueReusableCell(withIdentifier: "cellID") as UITableViewCell!
    if (cell == nil) {
      cell = UITableViewCell(style:.default, reuseIdentifier:"cellID")
    }
    cell?.textLabel!.text = self.accounts[indexPath.row].name
    cell?.textLabel!.font = UIFont.systemFont(ofSize: 14)
    return cell!
  }
  
}
