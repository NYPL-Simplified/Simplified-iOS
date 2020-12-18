import Foundation

@objcMembers final class NYPLAgeCheck : NSObject {
  // Static methods and vars
  static let sharedInstance = NYPLAgeCheck()

  @objc class func shared() -> NYPLAgeCheck
  {
    return NYPLAgeCheck.sharedInstance
  }
  

  // Members
  let serialQueue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier!).ageCheck")
  var handlerList = [((Bool) -> ())]()
  var isPresenting = false

  func verifyCurrentAccountAgeRequirement(_ completion: ((Bool) -> ())?) -> Void
  {
    serialQueue.async {
      let userAccount = NYPLUserAccount.sharedAccount()
      guard let accountDetails = AccountsManager.shared.currentAccount?.details else {
        completion?(false)
        return
      }
      
      if userAccount.needsAuth == true || accountDetails.userAboveAgeLimit {
        completion?(true)
        return
      }
      
      if !accountDetails.userAboveAgeLimit && NYPLSettings.shared.userPresentedAgeCheck {
        completion?(false)
        return
      }
      
      // We're already presenting the dialog, so queue the callback
      if self.isPresenting {
        if let completion = completion {
          self.handlerList.append(completion)
        }
        return
      }
      
      // Perform alert presentation
      self.isPresenting = true
      self.presentAgeVerificationView { over13 in
        NYPLSettings.shared.userPresentedAgeCheck = true
        if (over13) {
          accountDetails.userAboveAgeLimit = true
          completion?(true)
        } else {
          accountDetails.userAboveAgeLimit = false
          completion?(false)
        }

        self.isPresenting = false
        
        // Resolve queued callbacks
        self.serialQueue.async {
          for handler in self.handlerList {
            handler(accountDetails.userAboveAgeLimit)
          }
          self.handlerList.removeAll()
        }
      }
    }
  }
  
  fileprivate func presentAgeVerificationView(_ completion: @escaping (Bool) -> ()) -> Void
  {
    DispatchQueue.main.async {
      let alertCont = UIAlertController.init(
        title: NSLocalizedString("Age Verification", comment: "An alert title indicating the user needs to verify their age"),
        message: NSLocalizedString("You must be 13 years of age or older to download some of the books from this collection. How old are you?", comment: "An alert message telling the user they must be at least 13 years old and asking how old they are"),
        preferredStyle: .alert
      )
      alertCont.addAction(UIAlertAction.init(title: NSLocalizedString("Under 13", comment:"A button title indicating an under-age range"), style: .default, handler: { _ in
        completion(false)
      }))
      alertCont.addAction(UIAlertAction.init(title: NSLocalizedString("13 or Older", comment: "A button title indicating an age range"), style: .default, handler: { _ in
        completion(true)
      }))
      UIApplication.shared.keyWindow?.rootViewController?.present(alertCont, animated: true, completion: nil)
    }
  }
}
