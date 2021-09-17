import UIKit
import PureLayout


/// Welcome screen for a first-time user
@objcMembers final class NYPLWelcomeScreenViewController: UIViewController {
  
  var completion: ((Account) -> ())?
  
  required init(completion: ((Account) -> ())?) {
    self.completion = completion
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.view.backgroundColor = NYPLConfiguration.defaultBackgroundColor
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
                                 headline: NSLocalizedString("Read E-Books from Your Library", comment: "Title to tell users they can read books from a library they already have a card for."),
                                 subheadline: NSLocalizedString("Simply browse, borrow, and read free e-books from your local library.", comment: "Informs a user of the features of being able to check out a book in the app and even use more than one mobile device"),
                                 buttonTitle: NSLocalizedString("Find Your Library", comment: "Button that lets user know they can select a library they have a card for"),
                                 buttonTargetSelector: #selector(pickYourLibraryTapped))
    
    let view2 = splashScreenView("SplashInstantClassicsIcon",
                                 headline: NSLocalizedString("The SimplyE Collection", comment: "Title to show a user an option if they do not have a library card to check out books."),
                                 subheadline: nil,
                                 buttonTitle: NSLocalizedString("Add a Library Later", comment: "Name of section for free books means books that are well-known popular novels for many people."),
                                 buttonTargetSelector: #selector(instantClassicsTapped))
    
    let logoView = UIImageView(image: UIImage(named: "LaunchImageLogo"))
    logoView.contentMode = .scaleAspectFit
    
    let containerView = UIView()
    containerView.addSubview(logoView)
    containerView.addSubview(view1)
    containerView.addSubview(view2)
    
    self.view.addSubview(containerView)
    
    logoView.autoPinEdge(toSuperviewMargin: .top)
    logoView.autoAlignAxis(toSuperviewAxis: .vertical)

    view1.autoAlignAxis(toSuperviewAxis: .vertical)
    view1.autoPinEdge(.top, to: .bottom, of: logoView, withOffset: -12)
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
    
    NSLayoutConstraint.autoSetPriority(UILayoutPriority.defaultHigh) {
      containerView.autoSetDimension(.width, toSize: 350)
      containerView.autoAlignAxis(toSuperviewAxis: .horizontal)
    }
    NSLayoutConstraint.autoSetPriority(UILayoutPriority.defaultLow) {
      logoView.autoSetDimensions(to: CGSize(width: 180, height: 150))
      view2.autoPinEdge(toSuperviewEdge: .bottom, withInset: 80)
    }
  }
  
  func splashScreenView(_ imageName: String, headline: String, subheadline: String?, buttonTitle: String, buttonTargetSelector: Selector) -> UIView {
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
    if subheadline == nil {
      textLabel2.autoSetDimension(.height, toSize: 0)
    }
    
    let button = UIButton()
    button.setTitle(buttonTitle, for: UIControl.State())
    button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
    button.setTitleColor(NYPLConfiguration.iconLogoBlueColor(), for: .normal)
    button.layer.borderColor = NYPLConfiguration.iconLogoGreenColor().cgColor
    button.layer.borderWidth = 2
    button.layer.cornerRadius = 6

    button.contentEdgeInsets = UIEdgeInsets.init(top: 8.0, left: 10.0, bottom: 8.0, right: 10.0)
    button.addTarget(self, action: buttonTargetSelector, for: .touchUpInside)
    tempView.addSubview(button)
    
    button.autoPinEdge(.top, to: .bottom, of: textLabel2, withOffset: 8.0, relation: .equal)
    button.autoAlignAxis(toSuperviewMarginAxis: .vertical)
    button.autoPinEdge(toSuperviewMargin: .bottom)
    
    return tempView
  }
  
  func showLoadingFailureAlert() {
    let alert = NYPLAlertUtils.alert(title:nil, message:"We can’t get your library right now. Please close and reopen the app to try again.", style: .cancel)
    present(alert, animated: true, completion: nil)
  }
  
  func loadingOverlayView() -> UIView {
    let overlayView = UIView()
    overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
    let activityView = UIActivityIndicatorView(style: .whiteLarge)
    overlayView.addSubview(activityView)
    activityView.autoCenterInSuperviewMargins()
    activityView.startAnimating()
    return overlayView
  }
  
  private func addLoadingOverlayView(toVC viewController: UIViewController? = nil) -> UIView {
    let vc = viewController ?? self
    let loadingOverlay = loadingOverlayView()
    if !Thread.isMainThread {
      DispatchQueue.main.async {
        vc.view.addSubview(loadingOverlay)
        loadingOverlay.autoPinEdgesToSuperviewEdges()
      }
    } else {
      vc.view.addSubview(loadingOverlay)
      loadingOverlay.autoPinEdgesToSuperviewEdges()
    }
    return loadingOverlay
  }
  
  private func removeLoadingOverlayView(_ view: UIView?) {
    view?.removeFromSuperview()
  }

  func pickYourLibraryTapped() {
    if completion == nil {
      self.dismiss(animated: true, completion: nil)
      return
    }
    
    let pickLibrary = {
      let listVC = NYPLWelcomeScreenAccountList { account in
        if account.details != nil {
          self.completion?(account)
        } else {
          // Show loading overlay while we load the auth document
          let loadingOverlay = self.addLoadingOverlayView(toVC: self.navigationController)
          account.loadAuthenticationDocument { (success) in
            DispatchQueue.main.async {
              self.removeLoadingOverlayView(loadingOverlay)
              guard success else {
                self.showLoadingFailureAlert()
                return
              }
              if account.uuid != AccountsManager.NYPLAccountUUIDs[2] {
                NYPLSettings.shared.settingsAccountsList = [account.uuid, AccountsManager.NYPLAccountUUIDs[2]]
              } else {
                NYPLSettings.shared.settingsAccountsList = [AccountsManager.NYPLAccountUUIDs[2]]
              }
              self.completion?(account)
            }
          }
        }
      }
      self.navigationController?.pushViewController(listVC, animated: true)
    }

    if AccountsManager.shared.accountsHaveLoaded {
      pickLibrary()
    } else {
      // Show loading overlay while loading library list, which is required for pickLibrary
      let loadingOverlay = addLoadingOverlayView()
      AccountsManager.shared.loadCatalogs() { (success) in
        DispatchQueue.main.async {
          self.removeLoadingOverlayView(loadingOverlay)
          guard success else {
            self.showLoadingFailureAlert()
            return
          }
          pickLibrary()
        }
      }
    }
  }

  func instantClassicsTapped() {
    let classicsId = AccountsManager.NYPLAccountUUIDs[2]
    var loadingOverlay: UIView? = nil
    
    let selectInstantClassics = {
      guard let classicsAccount = AccountsManager.shared.account(classicsId) else {
        DispatchQueue.main.async {
          self.removeLoadingOverlayView(loadingOverlay)
          self.showLoadingFailureAlert()
        }
        return
      }
      // If we didn't add the loading overlay to load the library list, we need to add it now to load the auth document
      if loadingOverlay == nil {
        loadingOverlay = self.addLoadingOverlayView()
      }
      // Load the auth document for the classics library
      classicsAccount.loadAuthenticationDocument { (authSuccess) in
        DispatchQueue.main.async {
          self.removeLoadingOverlayView(loadingOverlay)
          if authSuccess {
            NYPLSettings.shared.settingsAccountsList = [classicsId]
            self.completion?(AccountsManager.shared.account(classicsId)!)
          } else {
            self.showLoadingFailureAlert()
          }
        }
      }
    }
    
    if AccountsManager.shared.accountsHaveLoaded {
      selectInstantClassics()
    } else {
      // Make sure the library list is loaded
      loadingOverlay = addLoadingOverlayView()
      AccountsManager.shared.loadCatalogs() { success in
        DispatchQueue.main.async {
          if success {
            selectInstantClassics()
          } else {
            self.removeLoadingOverlayView(loadingOverlay)
            self.showLoadingFailureAlert()
          }
        }
      }
    }
  }
}


/// List of available Libraries/Accounts to select as patron's primary
/// when going through Welcome Screen flow.
final class NYPLWelcomeScreenAccountList: UIViewController, UITableViewDelegate, UITableViewDataSource {
  
  var accounts: [Account]!
  var nyplAccounts: [Account]!
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
    self.tableView = self.view as? UITableView
    self.tableView.delegate = self
    self.tableView.dataSource = self
    
    self.accounts = AccountsManager.shared.accounts()

    //FIXME Replace with SettingsAccounts improvements to library selection VC
    //once that gets finalized and merged in.
    self.accounts.sort { $0.name < $1.name }
    self.nyplAccounts = self.accounts.filter { AccountsManager.NYPLAccountUUIDs.contains($0.uuid) }
    self.accounts = self.accounts.filter { !AccountsManager.NYPLAccountUUIDs.contains($0.uuid) }

    self.title = NSLocalizedString("Pick Your Library", comment: "Title that also informs the user that they should choose a library from the list.")
    self.view.backgroundColor = NYPLConfiguration.defaultBackgroundColor
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 100
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.section == 0 {
      completion(nyplAccounts[indexPath.row])
    } else {
      completion(accounts[indexPath.row])
    }
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      return self.nyplAccounts.count
    } else {
      return self.accounts.count
    }
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.section == 0 {
      return cellForLibrary(self.nyplAccounts[indexPath.row])
    } else {
      return cellForLibrary(self.accounts[indexPath.row])
    }
  }
  
  func cellForLibrary(_ account: Account) -> UITableViewCell {
    let cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "")
    
    let container = UIView()
    let textContainer = UIView()

    cell.accessoryType = .disclosureIndicator
    let imageView = UIImageView(image: account.logo)
    imageView.contentMode = .scaleAspectFit

    let textLabel = UILabel()
    textLabel.font = UIFont.systemFont(ofSize: 16)
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

    textContainer.autoPinEdge(.left, to: .right, of: imageView, withOffset: cell.contentView.layoutMargins.left * 2)
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
}
