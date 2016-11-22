import UIKit

/// This class is used to display the address listed as valid by the server
/// for the user to confirm or go back and edit.
final class ConfirmValidAddressViewController: TableViewController {
  fileprivate let addressStep: AddressStep
  fileprivate let validAddressAndCardType: (Address, CardType)
  
  fileprivate let configuration: CardCreatorConfiguration
  
  fileprivate let headerLabel: UILabel
  
  fileprivate static let addressCellReuseIdentifier = "addressCellReuseIdentifier"
  
  init(
    configuration: CardCreatorConfiguration,
    addressStep: AddressStep,
    validAddressAndCardType: (Address, CardType))
  {
    self.configuration = configuration
    self.addressStep = addressStep
    self.validAddressAndCardType = validAddressAndCardType
    
    self.headerLabel = UILabel()

    super.init(style: .grouped)

    self.tableView.register(
      AddressCell.self,
      forCellReuseIdentifier: ConfirmValidAddressViewController.addressCellReuseIdentifier)
    
    // Estimated cell height obtained via debugging. This must be set in order for the cells
    // to be sized automatically via `UITableViewAutomaticDimension` (which is the default).
    self.tableView.estimatedRowHeight = 64
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    headerLabel.numberOfLines = 0
    headerLabel.lineBreakMode = .byWordWrapping
    headerLabel.textColor = UIColor.darkGray
    headerLabel.textAlignment = .center

    switch self.addressStep {
    case .home:
      headerLabel.text = NSLocalizedString(
        "Confirm your home address, or go back to make changes.",
        comment: "Description meant to inform user to review their entered information")
    case .school:
      headerLabel.text = NSLocalizedString(
        "Confirm your school address, or go back to make changes.",
        comment: "Description meant to inform user to review their entered information")
    case .work:
      headerLabel.text = NSLocalizedString(
        "Confirm your work address, or go back to make changes.",
        comment: "Description meant to inform user to review their entered information")
    }
    
    self.tableView.allowsSelection = false
    self.tableView.tableHeaderView = self.headerLabel
    
    self.navigationItem.rightBarButtonItem =
      UIBarButtonItem(title: NSLocalizedString(
        "Confirm",
        comment: "A title for a button that confirms the address after the user has reviewed it"),
                      style: .plain,
                      target: self,
                      action: #selector(addressConfirmed))
  }
  
  override func viewDidLayoutSubviews() {
    let origin_x = self.tableView.tableHeaderView!.frame.origin.x
    let origin_y = self.tableView.tableHeaderView!.frame.origin.y
    let size = self.tableView.tableHeaderView!.sizeThatFits(CGSize(width: self.view.bounds.width, height: CGFloat.greatestFiniteMagnitude))
    
    let adjustedWidth = (size.width > CGFloat(375)) ? CGFloat(375.0) : size.width
    let padding = CGFloat(30.0)
    self.headerLabel.frame = CGRect(x: origin_x, y: origin_y, width: adjustedWidth, height: size.height + padding)
    
    self.tableView.tableHeaderView = self.headerLabel
  }
  
  // MARK: UITableViewDataSource
  
  func numberOfSectionsInTableView(_ tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let addressCell = tableView.dequeueReusableCell(
      withIdentifier: ConfirmValidAddressViewController.addressCellReuseIdentifier,
      for: indexPath)
      as! AddressCell
    addressCell.address = self.validAddressAndCardType.0
    return addressCell
  }
  
  // MARK: -

  func addressConfirmed() {
    let (address, cardType) = self.validAddressAndCardType
    self.addressStep.continueFlowWithValidAddress(
      self.configuration,
      viewController: self,
      address: address,
      cardType: cardType)
  }
}
