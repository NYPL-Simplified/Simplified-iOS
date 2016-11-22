import UIKit

/// This represents the user's progress in the registration flow.
enum AddressStep {
  /// The user is currently entering their home address.
  case home
  /// The user is currently entering their school address (and has previously entered
  /// the given home address).
  case school(homeAddress: Address)
  /// The user is currently entering their work address (and has previously entered
  /// the given home address).
  case work(homeAddress: Address)
  
  /// Returns the previously entered home address (if any).
  var homeAddress: Address? {
    get {
      switch self {
      case .home:
        return nil
      case let .school(homeAddress):
        return homeAddress
      case let .work(homeAddress):
        return homeAddress
      }
    }
  }
  
  fileprivate func pairWithAppendedAddress(_ address: Address) -> (Address, Address?) {
    if let homeAddress = self.homeAddress {
      return (homeAddress, address)
    } else {
      return (address, nil)
    }
  }
  
  /// Given a `Configuration`, the current `UIViewController`, an `Address` that has just
  /// been validated, and the `CardType` implied by the validated address, continue with the
  /// registration flow as appropriate.
  func continueFlowWithValidAddress(
    _ configuration: CardCreatorConfiguration,
    viewController: UIViewController,
    address: Address,
    cardType: CardType)
  {
    switch cardType {
    case .none:
      switch self {
      case .home:
        let alertController = UIAlertController(
          title: NSLocalizedString("Out-of-State Address", comment: ""),
          message: NSLocalizedString(
            ("Since you do not live in New York, you must work or attend school in New York to qualify for a "
              + "library card."),
            comment: "A message informing the user what they must assert given that they live outside NY"),
          preferredStyle: .alert)
        alertController.addAction(UIAlertAction(
          title: NSLocalizedString("I Work in New York", comment: ""),
          style: .default,
          handler: {_ in
            viewController.navigationController?.pushViewController(
              AddressViewController(configuration: configuration, addressStep: .work(homeAddress: address)),
              animated: true)
        }))
        alertController.addAction(UIAlertAction(
          title: NSLocalizedString("I Attend School in New York", comment: ""),
          style: .default,
          handler: {_ in
            viewController.navigationController?.pushViewController(
              AddressViewController(configuration: configuration, addressStep: .school(homeAddress: address)),
              animated: true)
        }))
        alertController.addAction(UIAlertAction(
          title: NSLocalizedString("Edit Home Address", comment: ""),
          style: .cancel,
          handler: {_ in
          viewController.navigationController?.popViewController(animated: true)
        }))
        viewController.present(alertController, animated: true, completion: nil)
      case .school:
        let alertController = UIAlertController(
          title: NSLocalizedString(
            "Card Denied",
            comment: "An alert title telling the user they cannot receive a library card"),
          message: NSLocalizedString(
            "You cannot receive a library card because your school address does not appear to be in New York.",
            comment: "An alert title telling the user they cannot receive a library card"),
          preferredStyle: .alert)
        alertController.addAction(UIAlertAction(
          title: NSLocalizedString("OK", comment: ""),
          style: .default,
          handler: nil))
        viewController.present(alertController, animated: true, completion: nil)
      case .work:
        let alertController = UIAlertController(
          title: NSLocalizedString(
            "Card Denied",
            comment: "An alert title telling the user they cannot receive a library card"),
          message: NSLocalizedString(
            "You cannot receive a library card because your work address does not appear to be in New York.",
            comment: "An alert title telling the user they cannot receive a library card"),
          preferredStyle: .alert)
        alertController.addAction(UIAlertAction(
          title: NSLocalizedString("OK", comment: ""),
          style: .default,
          handler: nil))
        viewController.present(alertController, animated: true, completion: nil)
      }
    case .temporary:
      let (homeAddress, schoolOrWorkAddress) = self.pairWithAppendedAddress(address)
      let nameAndEmailViewController = NameAndEmailViewController(
        configuration: configuration,
        homeAddress: homeAddress,
        schoolOrWorkAddress: schoolOrWorkAddress,
        cardType: cardType)
      viewController.navigationController?.pushViewController(nameAndEmailViewController, animated: true)
    case .standard:
      let (homeAddress, schoolOrWorkAddress) = self.pairWithAppendedAddress(address)
      let nameAndEmailViewController = NameAndEmailViewController(
        configuration: configuration,
        homeAddress: homeAddress,
        schoolOrWorkAddress: schoolOrWorkAddress,
        cardType: cardType)
      viewController.navigationController?.pushViewController(nameAndEmailViewController, animated: true)
    }
  }
}
