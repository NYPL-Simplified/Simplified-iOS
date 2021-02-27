import Foundation

protocol NYPLAgeCheckCompletionDelegate: class {
  func ageCheckCompleted(_ birthYear: Int)
  func ageCheckFailed()
}

@objc protocol NYPLAgeCheckVerification {
  func verifyCurrentAccountAgeRequirement(_ completion: ((Bool) -> ())?) -> Void
}

@objcMembers final class NYPLAgeCheck : NSObject, NYPLAgeCheckCompletionDelegate, NYPLAgeCheckVerification {
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
      
      // Queue the callback
      if let completion = completion {
        self.handlerList.append(completion)
      }
      
      // We're already presenting the age verification, return
      if self.isPresenting {
        return
      }
      
      let accountDetailsCompletion: ((Bool) -> ()) = { aboveAgeLimit in
        accountDetails.userAboveAgeLimit = aboveAgeLimit
      }
      self.handlerList.append(accountDetailsCompletion)
      
      // Perform age check presentation
      self.isPresenting = true
      self.presentAgeVerificationView()
    }
  }
  
  fileprivate func presentAgeVerificationView() {
    DispatchQueue.main.async {
      let vc = NYPLAgeCheckViewController(completionDelegate: self)
      let navigationVC = UINavigationController(rootViewController: vc)
      NYPLRootTabBarController.shared()?.safelyPresentViewController(navigationVC, animated: true, completion: nil)
    }
  }
  
  func ageCheckCompleted(_ birthYear: Int) {
    let aboveAgeLimit = Calendar.current.component(.year, from: Date()) - birthYear > 13
    NYPLSettings.shared.userPresentedAgeCheck = true
    self.isPresenting = false
    
    self.serialQueue.async {
      for handler in self.handlerList {
        handler(aboveAgeLimit)
      }
      self.handlerList.removeAll()
    }
  }
  
  func ageCheckFailed() {
    self.isPresenting = false
    NYPLSettings.shared.userPresentedAgeCheck = false
    self.serialQueue.async {
      self.handlerList.removeAll()
    }
  }
}
