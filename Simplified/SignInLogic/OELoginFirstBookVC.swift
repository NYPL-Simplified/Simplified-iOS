//
//  OELoginFirstBookVC.swift
//  Open eBooks
//
//  Created by Ettore Pasquini on 6/8/22.
//  Copyright © 2022 NYPL. All rights reserved.
//

import UIKit

class OELoginFirstBookVC: UIViewController {

  // MARK: - UI

  @IBOutlet var scrollView: UIScrollView!

  @IBOutlet var signInHeader: UILabel!

  @IBOutlet var accessCodeLabel: UILabel!
  @IBOutlet var accessCodeField: UITextField!
  @IBOutlet var pinLabel: UILabel!
  @IBOutlet var pinField: NYPLPasswordField!

  @IBOutlet var signInButton: UIButton!
  @IBOutlet var spinner: UIActivityIndicatorView!

  @IBOutlet var troublesButton: UIButton!
  @IBOutlet var faqButton: UIButton!

  private weak var postLoginConfigurator: OEAppUIStructureConfigurating?

  // MARK: - Validation logic

  private(set) var businessLogic: NYPLSignInBusinessLogic!

  private var frontEndValidator: NYPLUserAccountFrontEndValidation!

  /// There are situations where the user appears signed in, but their
  /// credentials are expired. In that case, it is desired to show the
  /// sign-in modal with prefilled yet editable values. This flag provides
  /// a way to do so in conjuction with the @p isSignedIn() function on
  /// the @p NYPLSignInBusinessLogic.
  var forceEditability: Bool = false

  // MARK: - Init / Deinit

  init(libraryAccount: Account,
       postLoginConfigurator: OEAppUIStructureConfigurating?) {
    self.postLoginConfigurator = postLoginConfigurator

    super.init(nibName: "OELoginFirstBookVC", bundle: nil)

    businessLogic = NYPLSignInBusinessLogic(
      libraryAccountID: libraryAccount.uuid,
      libraryAccountsProvider: AccountsManager.shared,
      urlSettingsProvider: NYPLSettings.shared,
      bookRegistry: NYPLBookRegistry.shared(),
      bookDownloadsRemover: NYPLMyBooksDownloadCenter.shared(),
      userAccountProvider: NYPLUserAccount.self,
      uiDelegate: self,
      drmAuthorizerAdobe: nil,
      drmAuthorizerAxis: NYPLAxisDRMAuthorizer.sharedInstance)

    let firstBookAuth = businessLogic.libraryAccount?.details?.auths.filter { auth in
      auth.isOauthClientCredentials
    }.first
    businessLogic.selectedIDP = nil
    businessLogic.selectedAuthentication = firstBookAuth

    frontEndValidator = NYPLUserAccountFrontEndValidation(
      account: libraryAccount,
      businessLogic: businessLogic,
      inputProvider: self)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  // MARK: - UIViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.titleView = OELoginNavHeader()

    // -- set up localized strings content
    signInHeader.text = NSLocalizedString("Sign In", comment: "")
    accessCodeLabel.text = NSLocalizedString("Access Code", comment: "")
    accessCodeField.placeholder = NSLocalizedString("Access Code", comment: "")
    pinLabel.text = NSLocalizedString("PIN", comment: "")
    pinField.placeholder = NSLocalizedString("PIN", comment: "")
    signInButton.setTitle(NSLocalizedString("Sign In", comment: ""),
                          for: .normal)
    troublesButton.setTitle(NSLocalizedString("Having trouble signing in?", comment: ""),
                            for: .normal)
    faqButton.setTitle(NSLocalizedString("Frequently Asked Questions", comment: ""),
                            for: .normal)

    // -- set up input methods
    if let selectedAuthentication = businessLogic.selectedAuthentication {
      switch selectedAuthentication.pinKeyboard {
      case .standard, .none:
        pinField.keyboardType = .asciiCapable
      case .email:
        pinField.keyboardType = .emailAddress
      case .numeric:
        pinField.keyboardType = .numberPad
      }
    }

    // -- set up custom look and feel
    accessCodeField.layer.borderWidth = 1
    pinField.layer.borderWidth = 1
    signInButton.layer.cornerRadius = NYPLConfiguration.cornerRadius
    updateSignInButton()
    updateStaticColors()
    updateTextFieldColors(forEditingField: nil)

    // -- set up validation hooks
    accessCodeField.delegate = frontEndValidator
    pinField.delegate = frontEndValidator

    // -- set up UI control logic
    registerForKeyboardNotifications()
    setUpKeyboardDismissal()
  }

  // this override is to fix colors in case the user transitions from Light
  // mode to Dark mode or viceversa.
  override func traitCollectionDidChange(_ previousTraits: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraits)

    if #available(iOS 12.0, *) {
      if let previousStyle = previousTraits?.userInterfaceStyle {
        if previousStyle != UIScreen.main.traitCollection.userInterfaceStyle {
          updateStaticColors()
          updateSignInButton()
          let selectedField: UITextField? = { [self] in
            if accessCodeField.isFirstResponder {
              return accessCodeField
            } else if pinField.isFirstResponder {
              return pinField
            } else {
              return nil
            }
          }()

          updateTextFieldColors(forEditingField: selectedField)
        }
      }
    }
  }

  // MARK: - Actions

  @IBAction func textFieldDidChange(_ sender: Any) {
    updateSignInButton()
  }

  @IBAction func didBeginEditingTextField(_ sender: Any) {
    guard let selectedTextField = sender as? UITextField else {
      updateTextFieldColors(forEditingField: nil)
      return
    }

    updateTextFieldColors(forEditingField: selectedTextField)
  }

  @IBAction func didTouchDownOnButton(_ sender: Any) {
    guard let button = sender as? UIButton else {
      return
    }

    button.backgroundColor = NYPLConfiguration.touchDownActionColor
  }

  @IBAction func didTouchUpOutsideButton(_ sender: Any) {
    updateSignInButton()
  }

  @IBAction func signIn() {
    Log.info(#function, "User tapped on Sign In button")
    businessLogic.logIn()
  }

  @IBAction func showTroubleshooting() {
    let url = URL(string: "https://www.openebooks.org/signin-help")!
    let vc = RemoteHTMLViewController(
      URL: url,
      title: NSLocalizedString("Help!", comment: "Title for Help page"),
      failureMessage: NSLocalizedString("The page could not load due to a connection error.", comment: "")
    )

    navigationController?.pushViewController(vc, animated: true)
  }

  @IBAction func showFAQ() {
    let url = URL(string: "https://www.openebooks.org/faq")!
    let vc = RemoteHTMLViewController(
      URL: url,
      title: NSLocalizedString("FAQ", comment: "Title for FAQ page"),
      failureMessage: NSLocalizedString("The page could not load due to a connection error.", comment: "")
    )

    navigationController?.pushViewController(vc, animated: true)
  }

  // MARK: - Helpers

  private func updateTextFieldColors(forEditingField selectedField: UITextField?) {
    guard let selectedField = selectedField else {
      accessCodeLabel.textColor = NYPLConfiguration.disabledFieldTextColor
      accessCodeField.layer.borderColor = NYPLConfiguration.disabledFieldTextColor.cgColor
      pinLabel.textColor = NYPLConfiguration.disabledFieldTextColor
      pinField.layer.borderColor = NYPLConfiguration.disabledFieldTextColor.cgColor
      return
    }

    if selectedField == accessCodeField {
      accessCodeLabel.textColor = NYPLConfiguration.actionColor
      accessCodeField.layer.borderColor = NYPLConfiguration.actionColor.cgColor
      pinLabel.textColor = NYPLConfiguration.disabledFieldTextColor
      pinField.layer.borderColor = NYPLConfiguration.disabledFieldTextColor.cgColor
    } else {
      accessCodeLabel.textColor = NYPLConfiguration.disabledFieldTextColor
      accessCodeField.layer.borderColor = NYPLConfiguration.disabledFieldTextColor.cgColor
      pinLabel.textColor = NYPLConfiguration.actionColor
      pinField.layer.borderColor = NYPLConfiguration.actionColor.cgColor
    }
  }

  private func updateSignInButton() {
    if frontEndValidator.canAttemptSignIn() {
      signInButton.isUserInteractionEnabled = true
      signInButton.backgroundColor = NYPLConfiguration.actionColor
    } else {
      signInButton.isUserInteractionEnabled = false
      signInButton.backgroundColor = NYPLConfiguration.disabledFieldTextColor
    }
  }

  private func updateStaticColors() {
    troublesButton?.setTitleColor(NYPLConfiguration.actionColor, for: .normal)
    faqButton?.setTitleColor(NYPLConfiguration.actionColor, for: .normal)
  }
  
  // MARK: - Keyboard bs

  private func registerForKeyboardNotifications() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(keyboardDidAppear(_:)),
                                           name: UIResponder.keyboardDidShowNotification,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(keyboardDidDisappear(_:)),
                                           name: UIResponder.keyboardDidHideNotification,
                                           object: nil)
  }

  @objc private func keyboardDidAppear(_ notification: NSNotification) {
    guard
      let info = notification.userInfo,
      let rect = info[UIResponder.keyboardFrameBeginUserInfoKey] as? CGRect
    else {
      return
    }

    let kbSize = rect.size
    let insets = UIEdgeInsets(top: 0, left: 0, bottom: kbSize.height, right: 0)
    scrollView.contentInset = insets
    scrollView.scrollIndicatorInsets = insets

    // If active text field is hidden by keyboard, scroll it so it's visible
    var viewableFrame = self.view.frame;
    viewableFrame.size.height -= kbSize.height;
    let activeField = [accessCodeField, pinField].first { $0.isFirstResponder }
    if let activeField = activeField {
      if !viewableFrame.contains(activeField.frame.origin) {
        let scrollPoint = CGPoint(x: 0, y: activeField.frame.origin.y-kbSize.height)
        scrollView.setContentOffset(scrollPoint, animated: true)
      }
    }
  }

  @objc private func keyboardDidDisappear(_ notification: NSNotification) {
    scrollView.contentInset = UIEdgeInsets.zero
    scrollView.scrollIndicatorInsets = UIEdgeInsets.zero
  }

  private func setUpKeyboardDismissal() {
    let tapGesture = UITapGestureRecognizer(target: self,
                                            action: #selector(didTapOnEmptySpace))
    view.addGestureRecognizer(tapGesture)
  }

  @objc private func didTapOnEmptySpace() {
    accessCodeField.resignFirstResponder()
    pinField.resignFirstResponder()
    updateTextFieldColors(forEditingField: nil)
  }
}

// MARK: -
extension OELoginFirstBookVC: NYPLSignInOutBusinessLogicUIDelegate {

  func businessLogicWillSignOut(_ businessLogic: NYPLSignInBusinessLogic) {
    // this VC is not used for signing out
  }

  func businessLogic(_ logic: NYPLSignInBusinessLogic,
                     didEncounterSignOutError error: Error?,
                     withHTTPStatusCode httpStatusCode: Int) {
    // this VC is not used for signing out
  }

  func businessLogicDidFinishDeauthorizing(_ logic: NYPLSignInBusinessLogic) {
    // this VC is not used for signing out
  }

  // MARK: - NYPLSignInBusinessLogicUIDelegate

  var context: String {
    "First Book login screen"
  }

  func businessLogicWillSignIn(_ businessLogic: NYPLSignInBusinessLogic) {
    signInButton.isUserInteractionEnabled = false
    spinner.startAnimating()
  }

  func businessLogicDidSignIn(_ businessLogic: NYPLSignInBusinessLogic) {
    NYPLMainThreadRun.asyncIfNeeded { [self] in
      signInButton.isUserInteractionEnabled = true
      spinner.stopAnimating()
      postLoginConfigurator?.setUpRootVC(userIsSignedIn: true)
    }
  }

  func businessLogic(_ logic: NYPLSignInBusinessLogic,
                     didEncounterValidationError error: Error?,
                     userFriendlyErrorTitle title: String?,
                     andMessage serverMessage: String?) {
    signInButton.isUserInteractionEnabled = true
    spinner.stopAnimating()

    let alert: UIAlertController!
    if serverMessage != nil {
      alert = NYPLAlertUtils.alert(title: title, message: serverMessage)
    } else {
      alert = NYPLAlertUtils.alert(title: title, error: error as? NSError)
    }

    self.present(alert, animated: true)
  }

  // MARK: - NYPLBasicAuthCredentialsProvider

  var username: String? {
    accessCodeField.text
  }

  var pin: String? {
    pinField.text
  }

  var requiresUserAuthentication: Bool {
    businessLogic.userAccount.requiresUserAuthentication
  }

  func hasCredentials() -> Bool {
    businessLogic.userAccount.hasCredentials()
  }

  // MARK: - NYPLOAuthTokenProvider

  var authToken: String? {
    businessLogic.userAccount.authToken
  }

  func setAuthToken(_ token: String) {
    businessLogic.userAccount.setAuthToken(token)
  }

  func hasOAuthClientCredentials() -> Bool {
    businessLogic.userAccount.hasOAuthClientCredentials()
  }

  var oauthTokenRefreshURL: URL? {
    businessLogic.userAccount.oauthTokenRefreshURL
  }

  // MARK: - NYPLUserAccountInputProvider

  var usernameTextField: UITextField? {
    accessCodeField
  }

  var PINTextField: UITextField? {
    pinField
  }
}
