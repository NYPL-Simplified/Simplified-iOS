import Foundation

final class AgeCheck : NSObject {

  class func verifyCurrentAccountAgeRequirement(_ completion: ((Bool) -> ())?) -> Void
  {
    let account = AccountsManager.shared.currentAccount
    
    if account.needsAuth == true || account.userAboveAgeLimit {
      completion?(true)
      return
    }
    
    if !account.userAboveAgeLimit && NYPLSettings.shared().userPresentedAgeCheck {
      completion?(false)
      return
    }
    
    presentAgeVerificationView { over13 in
      NYPLSettings.shared().userPresentedAgeCheck = true
      if (over13) {
        account.userAboveAgeLimit = true
        completion?(true)
      } else {
        account.userAboveAgeLimit = false
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
