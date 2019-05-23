import Foundation

@objcMembers final class AgeCheck : NSObject {

  class func verifyCurrentAccountAgeRequirement(_ completion: ((Bool) -> ())?) -> Void
  {
    guard let accountDetails = AccountsManager.shared.currentAccount?.details else {
      completion?(false)
      return
    }
    
    if accountDetails.needsAuth == true || accountDetails.userAboveAgeLimit {
      completion?(true)
      return
    }
    
    if !accountDetails.userAboveAgeLimit && NYPLSettings.shared().userPresentedAgeCheck {
      completion?(false)
      return
    }
    
    presentAgeVerificationView { over13 in
      NYPLSettings.shared().userPresentedAgeCheck = true
      if (over13) {
        accountDetails.userAboveAgeLimit = true
        completion?(true)
      } else {
        accountDetails.userAboveAgeLimit = false
        completion?(false)
      }
    }
  }
  
  fileprivate class func presentAgeVerificationView(_ completion: @escaping (Bool) -> ()) -> Void
  {
    let alertCont = NYPLAlertController.alert(withTitle: NSLocalizedString("WelcomeScreenAgeVerifyTitle", comment: "An alert title indicating the user needs to verify their age"), singleMessage: NSLocalizedString("WelcomeScreenAgeVerifyMessage", comment: "An alert message telling the user they must be at least 13 years old and asking how old they are"))
    
    alertCont?.addAction(UIAlertAction.init(title: "Under 13", style: .default, handler: { _ in
      completion(false)
    }))
    
    alertCont?.addAction(UIAlertAction.init(title: "13 or Older", style: .default, handler: { _ in
      completion(true)
    }))
    
    if let alertCont = alertCont {
      UIApplication.shared.keyWindow?.rootViewController?.present(alertCont, animated: true, completion: nil)
    }
  }
}
