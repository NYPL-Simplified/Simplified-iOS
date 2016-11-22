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
fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


/// This class is used to allow the user to enter their desired username and PIN.
final class UsernameAndPINViewController: FormTableViewController {
  
  fileprivate let configuration: CardCreatorConfiguration
  
  fileprivate let usernameCell: LabelledTextViewCell
  fileprivate let pinCell: LabelledTextViewCell
  fileprivate let homeAddress: Address
  fileprivate let schoolOrWorkAddress: Address?
  fileprivate let cardType: CardType
  fileprivate let fullName: String
  fileprivate let email: String
  
  fileprivate let session: AuthenticatingSession
  
  init(
    configuration: CardCreatorConfiguration,
    homeAddress: Address,
    schoolOrWorkAddress: Address?,
    cardType: CardType,
    fullName: String,
    email: String)
  {
    self.configuration = configuration
    self.usernameCell = LabelledTextViewCell(
      title: NSLocalizedString("Username", comment: "A username used to log into a service"),
      placeholder: NSLocalizedString("Required", comment: "A placeholder for a required text field"))
    self.pinCell = LabelledTextViewCell(
      title: NSLocalizedString("PIN", comment: "An abbreviation for personal identification number"),
      placeholder: NSLocalizedString("Required", comment: "A placeholder for a required text field"))
    
    self.homeAddress = homeAddress
    self.schoolOrWorkAddress = schoolOrWorkAddress
    self.cardType = cardType
    self.fullName = fullName
    self.email = email
    
    self.session = AuthenticatingSession(configuration: configuration)
    
    super.init(
      cells: [
        self.usernameCell,
        self.pinCell
      ])
    
    self.navigationItem.rightBarButtonItem?.isEnabled = false
    
    self.prepareTableViewCells()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.title = NSLocalizedString(
      "Username & PIN",
      comment: "A title for a screen asking the user for the user's username and PIN")
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
    
    self.usernameCell.textField.keyboardType = .alphabet
    self.usernameCell.textField.autocapitalizationType = .none
    self.usernameCell.textField.autocorrectionType = .no
    
    self.pinCell.textField.keyboardType = .numberPad
    self.pinCell.textField.inputAccessoryView = self.returnToolbar()
  }
  
  // MARK: UITableViewDataSource
  
  func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
    return NSLocalizedString("Usernames must be 5–25 letters and numbers only. PINs must be four digits.",
                             comment: "A description of valid usernames and PINs")
  }
  
  // MARK: UITextFieldDelegate
  
  @objc func textField(_ textField: UITextField,
                       shouldChangeCharactersInRange range: NSRange,
                                                     replacementString string: String) -> Bool
  {
    if !string.canBeConverted(to: String.Encoding.ascii) {
      return false
    }
    
    if textField == self.usernameCell.textField {
      if let _ = string.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) {
        return false
      } else if let text = textField.text {
        return text.characters.count - range.length + string.characters.count <= 25
      } else {
        return string.characters.count <= 25
      }
    }
    
    if textField == self.pinCell.textField {
      if let _ = string.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) {
        return false
      } else if let text = textField.text {
        return text.characters.count - range.length + string.characters.count <= 4
      } else {
        return string.characters.count <= 4
      }
    }
    
    fatalError()
  }
  
  // MARK: -
  
  @objc override func didSelectNext() {
    self.view.endEditing(false)
    self.navigationController?.view.isUserInteractionEnabled = false
    self.navigationItem.titleView =
      ActivityTitleView(title:
        NSLocalizedString(
          "Validating Name",
          comment: "A title telling the user their full name is currently being validated"))
    let request = NSMutableURLRequest(url: self.configuration.endpointURL.appendingPathComponent("validate/username"))
    let JSONObject: [String: String] = ["username": self.usernameCell.textField.text!]
    request.httpBody = try! JSONSerialization.data(withJSONObject: JSONObject, options: [.prettyPrinted])
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.timeoutInterval = self.configuration.requestTimeoutInterval
    let task = self.session.dataTaskWithRequest(request as URLRequest) { (data, response, error) in
      OperationQueue.main.addOperation {
        self.navigationController?.view.isUserInteractionEnabled = true
        self.navigationItem.titleView = nil
        if let error = error {
          let alertController = UIAlertController(
            title: NSLocalizedString("Error", comment: "The title for an error alert"),
            message: error.localizedDescription,
            preferredStyle: .alert)
          alertController.addAction(UIAlertAction(
            title: NSLocalizedString("OK", comment: ""),
            style: .default,
            handler: nil))
          self.present(alertController, animated: true, completion: nil)
          return
        }
        func showErrorAlert() {
          let alertController = UIAlertController(
            title: NSLocalizedString("Error", comment: "The title for an error alert"),
            message: NSLocalizedString(
              "A server error occurred during username validation. Please try again later.",
              comment: "An alert message explaining an error and telling the user to try again later"),
            preferredStyle: .alert)
          alertController.addAction(UIAlertAction(
            title: NSLocalizedString("OK", comment: ""),
            style: .default,
            handler: nil))
          self.present(alertController, animated: true, completion: nil)
        }
        if (response as! HTTPURLResponse).statusCode != 200 || data == nil {
          showErrorAlert()
          return
        }
        guard let validateUsernameResponse = ValidateUsernameResponse.responseWithData(data!) else {
          showErrorAlert()
          return
        }
        switch validateUsernameResponse {
        case .unavailableUsername:
          let alertController = UIAlertController(
            title: NSLocalizedString("Username Unavailable", comment: "The title for an error alert"),
            message: NSLocalizedString(
              "Your chosen username is already in use. Please choose another and try again.",
              comment: "An alert message explaining an error and telling the user to try again"),
            preferredStyle: .alert)
          alertController.addAction(UIAlertAction(
            title: NSLocalizedString("OK", comment: ""),
            style: .default,
            handler: nil))
          self.present(alertController, animated: true, completion: nil)
        case .invalidUsername:
          // We should never be here due to client-side validation, but we'll report it anyway.
          let alertController = UIAlertController(
            title: NSLocalizedString("Username Invalid", comment: "The title for an error alert"),
            message: NSLocalizedString(
              "Usernames must be 5–25 letters and numbers only. Please correct your username and try again.",
              comment: "An alert message explaining an error and telling the user to try again"),
            preferredStyle: .alert)
          alertController.addAction(UIAlertAction(
            title: NSLocalizedString("OK", comment: ""),
            style: .default,
            handler: nil))
          self.present(alertController, animated: true, completion: nil)
        case .availableUsername:
          self.moveToFinalReview()
        }
      }
    }
    
    task.resume()
  }

  @objc fileprivate func textFieldDidChange() {
    self.navigationItem.rightBarButtonItem?.isEnabled =
      (self.usernameCell.textField.text?.characters.count >= 5
        && self.pinCell.textField.text?.characters.count == 4)
  }
  
  fileprivate func moveToFinalReview() {
    self.view.endEditing(false)
    self.navigationController?.pushViewController(
      UserSummaryViewController(
        configuration: self.configuration,
        homeAddress: self.homeAddress,
        schoolOrWorkAddress: self.schoolOrWorkAddress,
        cardType: self.cardType,
        fullName: self.fullName,
        email: self.email,
        username: self.usernameCell.textField.text!,
        pin: self.pinCell.textField.text!),
      animated: true)
  }
  
}
