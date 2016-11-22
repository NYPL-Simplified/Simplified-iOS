import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


final class NameAndEmailViewController: FormTableViewController {
  
  fileprivate let configuration: CardCreatorConfiguration
  
  fileprivate let cardType: CardType
  fileprivate let fullNameCell: LabelledTextViewCell
  fileprivate let emailCell: LabelledTextViewCell
  fileprivate let homeAddress: Address
  fileprivate let schoolOrWorkAddress: Address?
  
  init(configuration: CardCreatorConfiguration,
       homeAddress: Address,
       schoolOrWorkAddress: Address?,
       cardType: CardType) {
    self.configuration = configuration
    self.fullNameCell = LabelledTextViewCell(
      title: NSLocalizedString("Full Name", comment: "The text field title for the full name of a user"),
      placeholder: NSLocalizedString("Required", comment: "A placeholder for a required text field"))
    self.emailCell = LabelledTextViewCell(
      title: NSLocalizedString("Email", comment: "A text field title for a user's email address"),
      placeholder: NSLocalizedString("Required", comment: "A placeholder for a required text field"))
    
    self.homeAddress = homeAddress
    self.schoolOrWorkAddress = schoolOrWorkAddress
    self.cardType = cardType
    
    super.init(
      cells: [
        self.fullNameCell,
        self.emailCell
      ])
    
    self.navigationItem.rightBarButtonItem?.isEnabled = false
    
    self.prepareTableViewCells()
  }
  
  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.title = NSLocalizedString(
      "Personal Information",
      comment: "A title for a screen asking the user for their personal information")
  }
  
  fileprivate func prepareTableViewCells() {
    for cell in self.cells {
      if let labelledTextViewCell = cell as? LabelledTextViewCell {
        labelledTextViewCell.selectionStyle = .none
        labelledTextViewCell.textField.delegate = self
        labelledTextViewCell.textField.addTarget(self,
                                                 action: #selector(textFieldDidChange),
                                                 for: .editingChanged)
      }
    }
    
    self.fullNameCell.textField.keyboardType = .alphabet
    self.fullNameCell.textField.autocapitalizationType = .words
    
    self.emailCell.textField.keyboardType = .emailAddress
    self.emailCell.textField.autocapitalizationType = .none
    self.emailCell.textField.autocorrectionType = .no
  }
  
  // MARK: -
  
  @objc override func didSelectNext() {
    self.view.endEditing(false)
    self.navigationController?.pushViewController(
      UsernameAndPINViewController(
        configuration: self.configuration,
        homeAddress: self.homeAddress,
        schoolOrWorkAddress: self.schoolOrWorkAddress,
        cardType: self.cardType,
        fullName: self.fullNameCell.textField.text!,
        email: self.emailCell.textField.text!),
      animated: true)
  }
  
  fileprivate func emailIsValid() -> Bool {
    let emailRegEx = ".+@.+\\..+"
    let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    return emailTest.evaluate(with: self.emailCell.textField.text!)
  }
  
  @objc fileprivate func textFieldDidChange() {
    if (self.emailIsValid()) {
        //Color-coding email can be reintroduced if required
        //self.emailCell.textField.textColor = UIColor.greenColor()
      self.navigationItem.rightBarButtonItem?.isEnabled =
        self.fullNameCell.textField.text?.characters.count > 0
    } else {
      if (self.emailCell.textField.isFirstResponder) {
        //self.emailCell.textField.textColor = UIColor.redColor()
      }
      self.navigationItem.rightBarButtonItem?.isEnabled = false
    }
  }
}
