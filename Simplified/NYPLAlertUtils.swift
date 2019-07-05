import Foundation
import UIKit

@objcMembers class NYPLAlertUtils : NSObject {
  class func alert(title: String?, error: NSError?) -> UIAlertController {
    var message = "UnknownError"
    let domain = error?.domain ?? ""
    let code = error?.code ?? 0
    
    if domain == NSURLErrorDomain {
      if code == NSURLErrorNotConnectedToInternet {
        message = "NotConnected"
      } else if code == NSURLErrorCancelled {
        message = "Cancelled"
      } else if code == NSURLErrorTimedOut {
        message = "TimedOut"
      } else {
        message = "UnknownRequestError"
      }
    }
    #if FEATURE_DRM_CONNECTOR
    if domain == NYPLADEPTErrorDomain {
      if code == NYPLADEPTErrorAuthenticationFailed {
        message = "SettingsAccountViewControllerInvalidCredentials"
      } else if code == NYPLADEPTErrorTooManyActivations {
        message = "SettingsAccountViewControllerMessageTooManyActivations"
      } else {
        message = "UnknownAdeptError"
      }
    }
    #endif
    
    return alert(title: title, message: message)
  }
  
  class func alert(title: String?, message: String?)-> UIAlertController {
    return alert(title: title, message: message, style: .default)
  }
  
  class func alert(title: String?, message: String?, style: UIAlertAction.Style)-> UIAlertController {
    let alertTitle = (title?.count ?? 0) > 0 ? NSLocalizedString(title!, comment: "") : "Alert"
    let alertMessage = (message?.count ?? 0) > 0 ? NSLocalizedString(message!, comment: "") : ""
    let alertController = UIAlertController.init(
      title: alertTitle,
      message: alertMessage,
      preferredStyle: .alert
      )
    alertController.addAction(UIAlertAction.init(title: NSLocalizedString("OK", comment: ""), style: style, handler: nil))
    return alertController
  }
  
  class func setProblemDocument(controller: UIAlertController?, document: NYPLProblemDocument?, append: Bool) {
    guard let controller = controller else {
      return
    }
    guard let document = document else {
      return
    }
    if append {
      let titleMsg = document.title != nil ? "\nErrorTitle: \(document.title!)" : ""
      let detailMsg = document.detail != nil ? "\nErrorDetails: \(document.detail!)" : ""
      controller.message = "\(controller.message ?? "")\(titleMsg)\(detailMsg)"
    } else {
      if document.title != nil {
        controller.title = document.title
      }
      if document.detail != nil {
        controller.message = document.detail
      }
    }
  }
  
  class func presentFromViewControllerOrNil(alertController: UIAlertController?, viewController: UIViewController?, animated: Bool, completion: (() -> Void)?) {
    guard let alertController = alertController else {
      return
    }
    if (viewController == nil) {
      NYPLRootTabBarController.shared()?.safelyPresentViewController(alertController, animated: animated, completion: completion)
    } else {
      viewController!.present(alertController, animated: animated, completion: completion)
      if alertController.message != nil {
        Log.info(#file, alertController.message!)
      }
    }
  }
}
