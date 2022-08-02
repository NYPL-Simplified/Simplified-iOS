//
//  NYPLUserAccountFrontEndValidation.swift
//  SimplyE
//
//  Created by Jacek Szyja on 26/05/2020.
//  Copyright © 2020 NYPL. All rights reserved.
//

import UIKit

/**
 Protocol that represents the input sources / UI requirements for performing
 front-end validation.
 */
@objc
protocol NYPLUserAccountInputProvider {
  var usernameTextField: UITextField? { get }
  var PINTextField: UITextField? { get }
  var forceEditability: Bool { get }
}

@objcMembers class NYPLUserAccountFrontEndValidation: NSObject {
  let account: Account
  private weak var businessLogic: NYPLSignInBusinessLogic?
  private weak var userInputProvider: NYPLUserAccountInputProvider?

  init(account: Account,
       businessLogic: NYPLSignInBusinessLogic?,
       inputProvider: NYPLUserAccountInputProvider) {

    self.account = account
    self.businessLogic = businessLogic
    self.userInputProvider = inputProvider
  }

  @objc func canAttemptSignIn() -> Bool {
    let username = userInputProvider?.usernameTextField?.text ?? ""
    let usernameHasText = username.trimmingCharacters(in: .whitespacesAndNewlines).count > 0
    let pin = userInputProvider?.PINTextField?.text ?? ""
    let pinHasText = pin.count > 0
    let selectedAuth = businessLogic?.selectedAuthentication
    let pinIsNotRequired = selectedAuth?.pinKeyboard == LoginKeyboard.none
    let isOAuthLogin = selectedAuth?.isOauthIntermediary ?? false

    return isOAuthLogin || usernameHasText && (pinHasText || pinIsNotRequired)
  }
}

extension NYPLUserAccountFrontEndValidation: UITextFieldDelegate {
  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    if let userInputProvider = userInputProvider, userInputProvider.forceEditability {
      return true
    }

    return !(businessLogic?.userAccount.hasBarcodeAndPIN() ?? false)
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    guard string.canBeConverted(to: .ascii) else { return false }

    if textField == userInputProvider?.usernameTextField,
      businessLogic?.selectedAuthentication?.patronIDKeyboard != .email {

      // Barcodes are numeric and usernames are alphanumeric including punctuation
      let allowedCharacters = CharacterSet.alphanumerics.union(.punctuationCharacters)
      let bannedCharacters = allowedCharacters.inverted

      guard string.rangeOfCharacter(from: bannedCharacters) == nil else { return false }

      if let text = textField.text {
        if range.location < 0 || range.location + range.length > text.count {
          return false
        }

        let updatedText = (text as NSString).replacingCharacters(in: range, with: string)
        // Usernames cannot be longer than 25 characters.
        guard updatedText.count <= 25 else { return false }
      }
    }

    if textField == userInputProvider?.PINTextField {
      let allowedCharacters = CharacterSet.decimalDigits
      let bannedCharacters = allowedCharacters.inverted

      let alphanumericPin = businessLogic?.selectedAuthentication?.pinKeyboard != .numeric
      let containsNonNumeric = !(string.rangeOfCharacter(from: bannedCharacters)?.isEmpty ?? true)
      let abovePinCharLimit: Bool
      let passcodeLength = businessLogic?.selectedAuthentication?.authPasscodeLength ?? 0

      if let text = textField.text,
        let textRange = Range(range, in: text) {

        let updatedText = text.replacingCharacters(in: textRange, with: string)
        abovePinCharLimit = updatedText.count > passcodeLength
      } else {
        abovePinCharLimit = false
      }

      // PIN's support numeric or alphanumeric.
      guard alphanumericPin || !containsNonNumeric else { return false }

      // PIN's character limit. Zero is unlimited.
      if passcodeLength == 0 {
        return true
      } else if abovePinCharLimit {
        return false
      }
    }

    return true
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if textField == userInputProvider?.usernameTextField {
      userInputProvider?.PINTextField?.becomeFirstResponder()
    } else if textField == userInputProvider?.PINTextField {
      if canAttemptSignIn() {
        businessLogic?.logIn()
      } else {
        return false
      }
    }

    return true
  }
}
