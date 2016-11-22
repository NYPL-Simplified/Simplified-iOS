import UIKit

/// This class is used for summarizing the user's details before
/// submitting the request to create a library card.
final class UserSummaryViewController: TableViewController {
  fileprivate var cells: [UITableViewCell]
  fileprivate let headerLabel: UILabel
  
  fileprivate let configuration: CardCreatorConfiguration
  fileprivate let session: AuthenticatingSession
  
  fileprivate let homeAddressCell: SummaryAddressCell
  fileprivate let altAddressCell: SummaryAddressCell
  fileprivate let cardType: CardType
  fileprivate let fullNameCell: UITableViewCell
  fileprivate let emailCell: UITableViewCell
  fileprivate let usernameCell: UITableViewCell
  fileprivate let pinCell: UITableViewCell
  
  fileprivate let homeAddress: Address
  fileprivate let schoolOrWorkAddress: Address?
  fileprivate let fullName: String
  fileprivate let email: String
  fileprivate let username: String
  fileprivate let pin: String
  
  init(
    configuration: CardCreatorConfiguration,
    homeAddress: Address,
    schoolOrWorkAddress: Address?,
    cardType: CardType,
    fullName: String,
    email: String,
    username: String,
    pin: String)
  {
    self.configuration = configuration
    self.session = AuthenticatingSession(configuration: configuration)

    self.homeAddress = homeAddress
    self.schoolOrWorkAddress = schoolOrWorkAddress
    self.cardType = cardType
    self.fullName = fullName
    self.email = email
    self.username = username
    self.pin = pin
    
    self.headerLabel = UILabel()
    
    self.homeAddressCell = SummaryAddressCell(section: NSLocalizedString(
      "Home Address",
      comment: "Title of the section for the user's home address"),
                                              style: .default, reuseIdentifier: nil)
    self.altAddressCell = SummaryAddressCell(section: NSLocalizedString(
      "School or Work Address",
      comment: "Title of the section for the user's possible work or school address"),
                                             style: .default, reuseIdentifier: nil)
  
    self.homeAddressCell.address = self.homeAddress
    if let address = self.schoolOrWorkAddress {
      self.altAddressCell.address = address
    }
    
    self.fullNameCell = SummaryCell(section: NSLocalizedString("Full Name", comment: "Title of the section for the user's full name"),
                                    cellText: self.fullName)
    self.emailCell = SummaryCell(section: NSLocalizedString("Email", comment: "Title of the section for the user's email"),
                                 cellText: self.email)
    self.usernameCell = SummaryCell(section: NSLocalizedString("Username", comment: "Title of the section for the user's chosen username"),
                                    cellText: self.username)
    self.pinCell = SummaryCell(section: NSLocalizedString("Pin", comment: "Title of the section for the user's PIN number"),
                               cellText: self.pin)

    self.cells = [
      self.homeAddressCell,
      self.fullNameCell,
      self.emailCell,
      self.usernameCell,
      self.pinCell
    ]

    if (self.schoolOrWorkAddress != nil) {
      self.cells.insert(self.altAddressCell, at: 1)
    }
    
    super.init(style: .plain)
    
    self.tableView.separatorStyle = .none
    
    self.navigationItem.rightBarButtonItem =
      UIBarButtonItem(title: NSLocalizedString(
        "Create Card",
        comment: "A title for a button that submits the user's information to create a library card"),
                      style: .plain,
                      target: self,
                      action: #selector(createPatron))

    self.prepareTableViewCells()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.tableView.backgroundColor = UIColor.groupTableViewBackground
    
    self.title = NSLocalizedString(
      "Review",
      comment: "A title for a screen letting the user know they can review the information they have entered")
    
    headerLabel.numberOfLines = 0
    headerLabel.lineBreakMode = .byWordWrapping
    headerLabel.textColor = UIColor.darkGray
    headerLabel.textAlignment = .center
    
    headerLabel.text = NSLocalizedString(
      "Before creating your card, please review and go back to make changes if necessary.",
      comment: "Description to inform a user to review their information, and press the back button to make changes if they are needed.")

    self.tableView.estimatedRowHeight = 120
    self.tableView.allowsSelection = false
    self.tableView.tableHeaderView = headerLabel
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
  
  fileprivate func prepareTableViewCells() {
    for cell in self.cells {
      cell.backgroundColor = UIColor.clear
      self.tableView.separatorStyle = .none
      
      if let labelledTextViewCell = cell as? LabelledTextViewCell {
        labelledTextViewCell.selectionStyle = .none
        labelledTextViewCell.textField.allowsEditingTextAttributes = false
      }
    }
  }
  
  // MARK: UITableViewDataSource
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1
  }
  
  func numberOfSectionsInTableView(_ tableView: UITableView) -> Int {
    return self.cells.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    return self.cells[indexPath.section]
  }
  
  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 0
  }
  
  func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    return 0
  }
  
  func tableView(_ tableView: UITableView, heightForRowAtIndexPath indexPath: IndexPath) -> CGFloat {
    return UITableViewAutomaticDimension
  }
  
  // MARK: -
  
  @objc fileprivate func createPatron() {
    self.navigationItem.rightBarButtonItem?.isEnabled = false
    self.navigationController?.view.isUserInteractionEnabled = false
    self.navigationItem.titleView =
      ActivityTitleView(title:
        NSLocalizedString(
          "Creating Card",
          comment: "A title telling the user their card is currently being created"))
    let request = NSMutableURLRequest(url: self.configuration.endpointURL.appendingPathComponent("create_patron"))
    let schoolOrWorkAddressOrNull: AnyObject = {
      if let schoolOrWorkAddress = self.schoolOrWorkAddress {
        return schoolOrWorkAddress.JSONObject() as AnyObject
      } else {
        return NSNull()
      }
    }()
    let JSONObject: [String: AnyObject] = [
      "name": self.fullName as AnyObject,
      "email": self.email as AnyObject,
      "address": self.homeAddress.JSONObject() as AnyObject,
      "username": self.username as AnyObject,
      "pin": self.pin as AnyObject,
      "work_or_school_address": schoolOrWorkAddressOrNull
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
          self.navigationItem.rightBarButtonItem?.isEnabled = true
          return
        }
        func showErrorAlert() {
          let alertController = UIAlertController(
            title: NSLocalizedString("Error", comment: "The title for an error alert"),
            message: NSLocalizedString(
              "A server error occurred during card creation. Please try again later.",
              comment: "An alert message explaining an error and telling the user to try again later"),
            preferredStyle: .alert)
          alertController.addAction(UIAlertAction(
            title: NSLocalizedString("OK", comment: ""),
            style: .default,
            handler: nil))
          self.present(alertController, animated: true, completion: nil)
          self.navigationItem.rightBarButtonItem?.isEnabled = true
        }
        if (response as! HTTPURLResponse).statusCode != 200 || data == nil {
          showErrorAlert()
          return
        }
        
        let JSONObject = try? JSONSerialization.jsonObject(with: data!, options: []) as! [String: AnyObject]
        let barcode = JSONObject?["barcode"] as? String
        
        self.navigationController?.pushViewController(
          UserCredentialsViewController(configuration: self.configuration,
            username: self.username,
            barcode: barcode,
            pin: self.pin,
            cardType: self.cardType),
        animated: true)
      }
    }
    
    task.resume()
  }

  
}
