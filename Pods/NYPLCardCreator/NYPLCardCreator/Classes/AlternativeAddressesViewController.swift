import UIKit

/// This class is used to display a list of addresses suggested by the server so
/// that the user can choose the correct address.
final class AlternativeAddressesViewController: TableViewController {
  fileprivate let addressStep: AddressStep
  fileprivate let alternativeAddressesAndCardTypes: [(Address, CardType)]
  fileprivate let headerLabel: UILabel
  
  fileprivate let configuration: CardCreatorConfiguration
  
  fileprivate static let addressCellReuseIdentifier = "addressCellReuseIdentifier"
  
  init(
    configuration: CardCreatorConfiguration,
    addressStep: AddressStep,
    alternativeAddressesAndCardTypes: [(Address, CardType)])
  {
    self.configuration = configuration
    self.addressStep = addressStep
    self.alternativeAddressesAndCardTypes = alternativeAddressesAndCardTypes
    
    self.headerLabel = UILabel()
    
    super.init(style: .grouped)
    
    self.tableView.register(
      AddressCell.self,
      forCellReuseIdentifier: AlternativeAddressesViewController.addressCellReuseIdentifier)
    
    // Estimated cell height obtained via debugging. This must be set in order for the cells
    // to be sized automatically via `UITableViewAutomaticDimension` (which is the default).
    self.tableView.estimatedRowHeight = 104
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    headerLabel.numberOfLines = 0
    headerLabel.lineBreakMode = .byWordWrapping
    headerLabel.textColor = UIColor.darkGray
    headerLabel.textAlignment = .center
    
    switch self.addressStep {
    case .home:
      self.title = NSLocalizedString(
        "Choose Home Address",
        comment: "A title for a screen asking the user to choose their home address from a list")
    case .school:
      self.title = NSLocalizedString(
        "Choose School Address",
        comment: "A title for a screen asking the user to choose their school address from a list")
    case .work:
      self.title = NSLocalizedString(
        "Choose Work Address",
        comment: "A title for a screen asking the user to choose their work address from a list")
    }
    
    self.headerLabel.text = NSLocalizedString(
      ("The address you entered matches more than one location. Please choose the correct address "
        + "from the list below."),
      comment: "A message telling the user to pick the correct address")
    
    self.tableView.tableHeaderView = headerLabel
  }
  
  override func viewDidLayoutSubviews() {
    let origin_x = self.tableView.tableHeaderView!.frame.origin.x
    let origin_y = self.tableView.tableHeaderView!.frame.origin.y
    let size = self.tableView.tableHeaderView!.sizeThatFits(CGSize(width: self.view.bounds.width, height: CGFloat.greatestFiniteMagnitude))
    
    let adjustedWidth = (size.width > CGFloat(375)) ? CGFloat(375.0) : size.width
    let padding = CGFloat(30.0)
    headerLabel.frame = CGRect(x: origin_x, y: origin_y, width: adjustedWidth, height: size.height + padding)
    
    self.tableView.tableHeaderView = self.headerLabel
  }
  
  // MARK: UITableViewDelegate
  
  func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
    let (address, cardType) = self.alternativeAddressesAndCardTypes[indexPath.row]
    self.addressStep.continueFlowWithValidAddress(
      self.configuration,
      viewController: self,
      address: address,
      cardType: cardType)
  }
  
  // MARK: UITableViewDataSource
  
  func numberOfSectionsInTableView(_ tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.alternativeAddressesAndCardTypes.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let addressCell = tableView.dequeueReusableCell(
      withIdentifier: AlternativeAddressesViewController.addressCellReuseIdentifier,
      for: indexPath)
      as! AddressCell
    addressCell.address = self.alternativeAddressesAndCardTypes[indexPath.row].0
    return addressCell
  }
}
