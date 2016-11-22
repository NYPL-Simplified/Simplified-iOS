import UIKit

/// The superclass for all form-like view controllers in the application. It provides
/// for cell navigation via a "Return" button, management of the "Next" button for going
/// to the next step of the registration flow, and implements `UITableViewDataSource`.
///
/// **Note:** The `didSelectNext` method should be overridden in all subclasses to advance
/// the registration flow as appropriate. The default behavior is to do nothing.
class FormTableViewController: TableViewController, UITextFieldDelegate {
  let cells: [UITableViewCell]
  
  init(cells: [UITableViewCell]) {
    self.cells = cells
    super.init(style: .grouped)
    
    self.navigationItem.rightBarButtonItem =
      UIBarButtonItem(title: NSLocalizedString("Next", comment: "A title for a button that goes to the next screen"),
                      style: .plain,
                      target: self,
                      action: #selector(didSelectNext))
  }

  /// Returns a `UIToolbar` with a "Return" button that advances to the next text field.
  func returnToolbar() -> UIToolbar {
    let flexibleSpaceBarButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    let nextBarButtonItem = UIBarButtonItem(
      title: NSLocalizedString("Return", comment: "The title of the button that goes to the next line in a form"),
      style: .plain,
      target: self,
      action: #selector(advanceToNextTextField))
    
    let toolbar = UIToolbar()
    toolbar.setItems([flexibleSpaceBarButtonItem, nextBarButtonItem], animated: false)
    toolbar.sizeToFit()
    
    return toolbar
  }
  
  @objc fileprivate func advanceToNextTextField() {
    var firstResponser: LabelledTextViewCell? = nil
    
    for cell in self.cells {
      if let labelledTextViewCell = cell as? LabelledTextViewCell {
        // Skip fields that are not enabled, e.g. the region field when entering school
        // or work addresses.
        if firstResponser != nil && labelledTextViewCell.textField.isUserInteractionEnabled {
          labelledTextViewCell.textField.becomeFirstResponder()
          return
        }
        if labelledTextViewCell.textField.isFirstResponder {
          firstResponser = labelledTextViewCell
        }
      }
    }
    
    firstResponser?.textField.resignFirstResponder()
  }
  
  // MARK: UITableViewDataSource
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.cells.count
  }
  
  func numberOfSectionsInTableView(_ tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    return self.cells[indexPath.row]
  }
  
  // MARK: UITextFieldDelegate
  
  @objc func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    self.advanceToNextTextField()
    return true
  }
  
  // MARK: -
  
  /// Should be overridden in subclasses of `FormTableViewController`.
  func didSelectNext() {
    
  }
}
