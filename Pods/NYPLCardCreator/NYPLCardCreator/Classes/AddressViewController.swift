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


/// This class is used for allowing the user to enter an address.
final class AddressViewController: FormTableViewController {
  
  fileprivate let configuration: CardCreatorConfiguration
  
  fileprivate let addressStep: AddressStep
  fileprivate let street1Cell: LabelledTextViewCell
  fileprivate let street2Cell: LabelledTextViewCell
  fileprivate let cityCell: LabelledTextViewCell
  fileprivate let regionCell: LabelledTextViewCell
  fileprivate let zipCell: LabelledTextViewCell
  
  fileprivate let session: AuthenticatingSession
  
  init(configuration: CardCreatorConfiguration, addressStep: AddressStep) {
    self.configuration = configuration
    self.addressStep = addressStep
    self.street1Cell = LabelledTextViewCell(
      title: NSLocalizedString("Street 1", comment: "The first line of a US street address"),
      placeholder: NSLocalizedString("Required", comment: "A placeholder for a required text field"))
    self.street2Cell = LabelledTextViewCell(
      title: NSLocalizedString("Street 2", comment: "The second line of a US street address (optional)"),
      placeholder: NSLocalizedString("Optional", comment: "A placeholder for an optional text field"))
    self.cityCell = LabelledTextViewCell(
      title: NSLocalizedString("City", comment: "The city portion of a US postal address"),
      placeholder: NSLocalizedString("Required", comment: "A placeholder for a required text field"))
    self.regionCell = LabelledTextViewCell(
      title: NSLocalizedString("State", comment: "The common name for one of the states or regions in the US"),
      placeholder: NSLocalizedString("Required", comment: "A placeholder for a required text field"))
    self.zipCell = LabelledTextViewCell(
      title: NSLocalizedString("ZIP", comment: "The common name for a US ZIP code"),
      placeholder: NSLocalizedString("Required", comment: "A placeholder for a required text field"))
    
    self.session = AuthenticatingSession(configuration: configuration)

    super.init(
      cells: [
        self.street1Cell,
        self.street2Cell,
        self.cityCell,
        self.regionCell,
        self.zipCell
      ])
    
    self.navigationItem.rightBarButtonItem?.isEnabled = false
    self.prepareTableViewCells()
  }
  
  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  deinit {
    self.session.invalidateAndCancel()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    switch self.addressStep {
    case .home:
      self.title = NSLocalizedString(
        "Home Address",
        comment: "A title for a screen asking the user for their home address")
    case .school:
      self.title = NSLocalizedString(
        "School Address",
        comment: "A title for a screen asking the user for their school address")
    case .work:
      self.title = NSLocalizedString(
        "Work Address",
        comment: "A title for a screen asking the user for their work address")
    }
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
    
    self.street1Cell.textField.keyboardType = .alphabet
    self.street1Cell.textField.autocapitalizationType = .words
    
    self.street2Cell.textField.keyboardType = .alphabet
    self.street2Cell.textField.autocapitalizationType = .words
    
    self.cityCell.textField.keyboardType = .alphabet
    self.cityCell.textField.autocapitalizationType = .words
    
    self.regionCell.textField.keyboardType = .alphabet
    
    switch self.addressStep {
    case .home:
      break
    case .school:
      fallthrough
    case .work:
      self.regionCell.textField.isUserInteractionEnabled = false
      self.regionCell.textField.text = "New York"
      self.regionCell.textField.textColor = UIColor.gray
    }
    
    self.zipCell.textField.keyboardType = .numberPad
    self.zipCell.textField.inputAccessoryView = self.returnToolbar()
    self.zipCell.textField.addTarget(self,
                                     action: #selector(zipTextFieldDidChange),
                                     for: .allEditingEvents)
  }
  
  // MARK: UITextFieldDelegate
  
  @objc func textField(_ textField: UITextField,
                       shouldChangeCharactersInRange range: NSRange,
                                                     replacementString string: String) -> Bool
  {
    
    if textField == self.zipCell.textField {
      if let text = textField.text {
        return self.isPossibleStartOfValidZIPCode(
          (text as NSString).replacingCharacters(in: range, with: string))
      } else {
        return self.isPossibleStartOfValidZIPCode(string)
      }
    }
    
    return true
  }
  
  // MARK: -
  
  @objc override func didSelectNext() {
    self.view.endEditing(false)
    self.submit()
  }
  
  fileprivate func isPossibleStartOfValidZIPCode(_ string: String) -> Bool {
    if string.contains("-") {
      if string.characters.count > 10 {
        return false
      }
    } else {
      if string.characters.count > 9 {
        return false
      }
    }
    
    for (i, c) in zip(0..<10, string.characters) {
      if !(c >= "0" && c <= "9") {
        if i == 5 {
          if c != "-" {
            return false
          }
        } else {
          return false
        }
      }
    }
    
    return true
  }
  
  fileprivate func isValidZIPCode(_ string: String) -> Bool {
    return isPossibleStartOfValidZIPCode(string) && (string.characters.count == 5 || string.characters.count == 10)
  }
  
  @objc fileprivate func zipTextFieldDidChange() {
    if let text = self.zipCell.textField.text {
      if text.characters.count > 5 && !text.contains("-") {
        let index = text.characters.index(text.startIndex, offsetBy: 5)
        self.zipCell.textField.text = text.substring(to: index) + "-" + text.substring(from: index)
      } else if text.characters.count == 6 && text.contains("-") {
        self.zipCell.textField.text = text.replacingOccurrences(of: "-", with: "")
      }
      self.textFieldDidChange()
    }
  }
  
  @objc fileprivate func textFieldDidChange() {
    self.navigationItem.rightBarButtonItem?.isEnabled =
      (self.street1Cell.textField.text?.characters.count > 0
        && self.cityCell.textField.text?.characters.count > 0
        && self.regionCell.textField.text?.characters.count > 0
        && self.zipCell.textField.text?.characters.count > 0
        && self.isValidZIPCode(self.zipCell.textField.text!))
  }
  
  fileprivate func currentAddress() -> Address? {
    guard let
      street1 = self.street1Cell.textField.text,
      let city = self.cityCell.textField.text,
      let region = self.regionCell.textField.text,
      let zip = self.zipCell.textField.text
      else
    {
      return nil
    }
    
    return Address(street1: street1, street2: self.street2Cell.textField.text, city: city, region: region, zip: zip)
  }
  
  fileprivate func submit() {
    self.navigationController?.view.isUserInteractionEnabled = false
    self.navigationItem.titleView =
      ActivityTitleView(title:
        NSLocalizedString(
          "Validating Address",
          comment: "A title telling the user their address is currently being validated"))
    let request = NSMutableURLRequest(
      url: self.configuration.endpointURL.appendingPathComponent("validate/address"))
    let isSchoolOrWorkAddress: Bool = {
      switch self.addressStep {
      case .home:
        return false
      case .school:
        return true
      case .work:
        return true
      }
    }()
    let JSONObject: [String: AnyObject] = [
      "address": self.currentAddress()!.JSONObject() as AnyObject,
      "is_work_or_school_address": isSchoolOrWorkAddress as AnyObject
    ]
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
              "A server error occurred during address validation. Please try again later.",
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
        guard let validateAddressResponse = ValidateAddressResponse.responseWithData(data!) else {
          showErrorAlert()
          return
        }
        switch validateAddressResponse {
        case let .validAddress(_, address, cardType):
            let viewController = ConfirmValidAddressViewController(
                configuration: self.configuration,
                addressStep: self.addressStep,
                validAddressAndCardType: (address, cardType))
            self.navigationController?.pushViewController(viewController, animated: true)
        case let .alternativeAddresses(_, addressTuples):
          let viewController = AlternativeAddressesViewController(
            configuration: self.configuration,
            addressStep: self.addressStep,
            alternativeAddressesAndCardTypes: addressTuples)
          self.navigationController?.pushViewController(viewController, animated: true)
        case .unrecognizedAddress:
          let alertController = UIAlertController(
            title: NSLocalizedString(
              "Unrecognized Address",
              comment: "An alert title telling the user their address was not recognized by the server"),
            message: NSLocalizedString(
              "Your address could not be verified. Please try another address.",
              comment: "An alert message telling the user their address was not recognized by the server"),
            preferredStyle: .alert)
          alertController.addAction(UIAlertAction(
            title: NSLocalizedString("OK", comment: ""),
            style: .default,
            handler: nil))
          self.present(alertController, animated: true, completion: nil)
        }
      }
    }
    
    task.resume()
  }
}
