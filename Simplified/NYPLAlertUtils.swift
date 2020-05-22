import Foundation
import UIKit

@objcMembers class NYPLAlertUtils : NSObject {
  /**
    Generates an alert view from errors of domains: NSURLErrorDomain, NYPLADEPTErrorDomain

   - Parameter title: The alert title; can be a localization key.
    - Parameter error: An error. If the error contains a localizedDescription, that will be used for the alert message.
    - Returns: The alert controller to be presented.
   */
  class func alert(title: String?, error: NSError?) -> UIAlertController {
    var message = ""
    let domain = error?.domain ?? ""
    let code = error?.code ?? 0

    // handle common iOS networking errors
    if domain == NSURLErrorDomain {
      if code == NSURLErrorNotConnectedToInternet {
        message = "NotConnected"
      } else if code == NSURLErrorCancelled {
        message = "Cancelled"
      } else if code == NSURLErrorTimedOut {
        message = "TimedOut"
      } else if code == NSURLErrorUnsupportedURL {
        message = "UnsupportedURL"
      } else {
        message = "UnknownRequestError"
      }
    }
    #if FEATURE_DRM_CONNECTOR
    if domain == NYPLADEPTErrorDomain {
      if code == NYPLADEPTError.authenticationFailed.rawValue {
        message = "SettingsAccountViewControllerInvalidCredentials"
      } else if code == NYPLADEPTError.tooManyActivations.rawValue {
        message = "SettingsAccountViewControllerMessageTooManyActivations"
      } else {
        message = "UnknownAdeptError"
      }
    }
    #endif

    if message.isEmpty {
      // since it wasn't a networking or Adobe DRM error, show the error
      // description if present
      if let errorDescription = error?.localizedDescription, !errorDescription.isEmpty {
        message = errorDescription
      } else {
        message = "UnknownError"
        NYPLErrorLogger.logError(withCode: .genericErrorMsgDisplayed,
                                 context: NYPLErrorLogger.Context.errorHandling.rawValue,
                                 message: "Error \(error?.description ?? "") contained no usable error message for the user, so we defaulted to a generic one.")
      }
    }

    return alert(title: title, message: message)
  }
  
  /**
    Generates an alert view with localized strings and default style
    @param title the alert title; can be localization key
    @param message the alert message; can be localization key
    @return the alert
   */
  class func alert(title: String?, message: String?) -> UIAlertController {
    return alert(title: title, message: message, style: .default)
  }
  
  /**
    Generates an alert view with localized strings
    @param title the alert title; can be localization key
    @param message the alert message; can be localization key
    @param style the OK action style
    @return the alert
   */
  class func alert(title: String?, message: String?, style: UIAlertAction.Style) -> UIAlertController {
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
  
  /**
    Adds a problem document's contents to the alert
    @param controller the alert to modify
    @param document the problem document
    @param append appends the problem document title and details to the alert if true; sets the alert title and message to problem document contents otherwise
    @return
   */
  class func setProblemDocument(controller: UIAlertController?, document: NYPLProblemDocument?, append: Bool) {
    guard let controller = controller else {
      return
    }
    guard let document = document else {
      return
    }

    if append == false {
      controller.title = document.title
      controller.message = document.detail
      return
    }

    var titleWasAdded = false
    if controller.title?.isEmpty ?? true {
      controller.title = document.title
      titleWasAdded = true
    }

    let existingMsg: String = {
      if let existingMsg = controller.message, !existingMsg.isEmpty {
        return existingMsg + "\n"
      }
      return ""
    }()

    let docDetail: String = document.detail ?? ""

    if !titleWasAdded, let docTitle = document.title, !docTitle.isEmpty {
      controller.message = "\(existingMsg)\(docTitle)\n\(docDetail)"
    } else {
      controller.message = "\(existingMsg)\(docDetail)"
    }
  }
  
  /**
    Presents an alert view from another given view
    @param alertController the alert to display
    @param viewController the view from which the alert is displayed
    @param animated true/false for animation
    @param completion callback passed on to UIViewcontroller::present
    @return
   */
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
