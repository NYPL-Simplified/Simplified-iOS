//
//  NYPLAgeCheckViewController.swift
//  Simplified
//
//  Created by Ernest Fan on 2021-02-22.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import UIKit

class NYPLAgeCheckViewController: UIViewController {

  // Constants
  let textFieldHeight: CGFloat = 40.0
  
  fileprivate var birthYearSelected = 0
  
  weak var ageCheckDelegate: NYPLAgeCheckValidationDelegate?
  
  init(ageCheckDelegate: NYPLAgeCheckValidationDelegate) {
    self.ageCheckDelegate = ageCheckDelegate
    
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.setupView()
  }
  
  // We need to fail the age check because user can swipe down to dismiss the view controller in iOS 13+
  deinit {
    if !(ageCheckDelegate?.ageCheckCompleted ?? false) {
      ageCheckDelegate?.didFailAgeCheck()
    }
  }
  
  @objc func completeAgeCheck() {
    guard ageCheckDelegate?.isValid(birthYear: birthYearSelected) ?? false else {
      return
    }
    
    ageCheckDelegate?.didCompleteAgeCheck(birthYearSelected)
    ageCheckDelegate?.ageCheckCompleted = true
    dismiss(animated: true, completion: nil)
  }
  
  // MARK: - UI
  
  func updateBarButton() {
    rightBarButtonItem.isEnabled = ageCheckDelegate?.isValid(birthYear: birthYearSelected) ?? false
  }
  
  @objc func hidePickerView() {
    self.view.endEditing(true)
  }
  
  func setupView() {
    self.title = NSLocalizedString("Age Verification", comment: "Title for Age Verification")
    
    view.backgroundColor = NYPLConfiguration.primaryBackgroundColor
    
    navigationItem.setRightBarButton(rightBarButtonItem, animated: true)
    
    inputTextField.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    
    view.addSubview(inputTextField)
    view.addSubview(titleLabel)
    
    inputTextField.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    inputTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50).isActive = true
    inputTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50).isActive = true
    inputTextField.heightAnchor.constraint(equalToConstant: textFieldHeight).isActive = true
    view.bringSubviewToFront(inputTextField)
    
    titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    titleLabel.bottomAnchor.constraint(equalTo: view.centerYAnchor, constant: -30).isActive = true
    titleLabel.widthAnchor.constraint(equalTo: inputTextField.widthAnchor).isActive = true
    titleLabel.heightAnchor.constraint(equalToConstant: textFieldHeight).isActive = true
    view.bringSubviewToFront(titleLabel)
  }
  
  // MARK: - UI Components
  
  let titleLabel: UILabel = {
    let label = UILabel()
    label.text = NSLocalizedString("Please enter your birth year", comment: "Caption for asking user to enter their birth year")
    label.textAlignment = .center
    label.font = UIFont.customFont(forTextStyle: .headline)
    return label
  }()
  
  lazy var pickerView: UIPickerView = {
    let view = UIPickerView()
    view.dataSource = self
    view.delegate = self
    return view
  }()
  
  lazy var inputTextField: UITextField = {
    let textfield = UITextField()
    textfield.text = ""
    
    textfield.delegate = self

    // Input View
    // UIToolbar gives an autolayout warning on iOS 13 if initialized by UIToolbar()
    // Initialize the toolbar with a frame like below fixes this issue
    // @seealso https://stackoverflow.com/questions/54284029/uitoolbar-with-uibarbuttonitem-layoutconstraint-issue
    
    let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 30))
    toolbar.sizeToFit()
    let doneButton = UIBarButtonItem(title: NSLocalizedString("Done", comment: "Button title for hiding picker view"), style: .plain, target: self, action: #selector(hidePickerView))
    let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)

    toolbar.setItems([spaceButton, doneButton], animated: false)

    textfield.inputAccessoryView = toolbar
    textfield.inputView = pickerView
    
    // Styling
    let placeHolderString = NSLocalizedString("Select Year", comment: "Placeholder for birth year textfield")
    textfield.attributedPlaceholder = NSAttributedString(string: placeHolderString, attributes: [NSAttributedString.Key.foregroundColor: NYPLConfiguration.primaryTextColor])
    textfield.layer.borderColor = NYPLConfiguration.fieldBorderColor.cgColor
    
    textfield.layer.borderWidth = 0.5
    
    textfield.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: textFieldHeight))
    let image = UIImage(named: "ArrowDown")?.withRenderingMode(.alwaysTemplate)
    let imageView = UIImageView(image:image)
    imageView.tintColor = NYPLConfiguration.primaryTextColor
    textfield.rightView = imageView
    textfield.leftViewMode = .always
    textfield.rightViewMode = .always
    
    return textfield
  }()
  
  lazy var rightBarButtonItem: UIBarButtonItem = {
    let item = UIBarButtonItem(title: NSLocalizedString("Next", comment: "Button title for completing age verification"), style: .plain, target: self, action: #selector(completeAgeCheck))
    item.tintColor = NYPLConfiguration.actionColor
    item.isEnabled = false
    return item
  }()
}

// MARK: - UITextFieldDelegate

extension NYPLAgeCheckViewController: UITextFieldDelegate {
  // Handle user's input by physical keyboard
  func textFieldDidChangeSelection(_ textField: UITextField) {
    birthYearSelected = Int(textField.text ?? "") ?? 0
    updateBarButton()
  }
}

// MARK: - UIPickerViewDelegate/Datasource

extension NYPLAgeCheckViewController: UIPickerViewDelegate, UIPickerViewDataSource {
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }
  
  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return ageCheckDelegate?.birthYearList.count ?? 0
  }
  
  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    guard let delegate = ageCheckDelegate else {
      return ""
    }
    return "\(delegate.birthYearList[row])"
  }
  
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    guard let delegate = ageCheckDelegate else {
      return
    }
    inputTextField.text = "\(delegate.birthYearList[row])"
    birthYearSelected = delegate.birthYearList[row]
    updateBarButton()
  }
}
