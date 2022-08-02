import Foundation
import UIKit

@objcMembers class NYPLAlertUtils : NSObject {
  /**
   Generates an alert view controller. If the `message` is non-nil, it will be
   used instead of deriving the error message from the `error`.

   - Parameter title: The alert title; can be a localization key.
   - Parameter error: An error. If the error contains a localizedDescription, that will be used for the alert message.
   - Returns: The alert controller to be presented.
   */
  class func alert(title: String?,
                   message: String?,
                   error: NSError?) -> UIAlertController {
    if let message = message {
      return alert(title: title, message: message)
    } else {
      return alert(title: title, error: error)
    }
  }

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
        message = "DRM error: \(error?.localizedDescriptionWithRecovery ?? "Please try again.")"
      }
    }
    #endif

    if message.isEmpty {
      // since it wasn't a networking or Adobe DRM error, show the error
      // description if present
      if let errorDescription = error?.localizedDescriptionWithRecovery, !errorDescription.isEmpty {
        message = errorDescription
      } else {
        message = "An error occurred. Please try again later or report an issue from the Settings tab."
        var metadata = [String: Any]()
        metadata["alertTitle"] = title ?? "N/A"
        if let error = error {
          metadata["error"] = error
          metadata["message"] = "Error object contained no usable error message for the user, so we defaulted to a generic one."
        }
        NYPLErrorLogger.logError(withCode: .genericErrorMsgDisplayed,
                                 summary: "Displayed error alert with generic message",
                                 metadata: metadata)
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
    guard let alert = controller else {
      return
    }
    guard let document = document else {
      return
    }

    var titleWasAdded = false
    var detailWasAdded = false
    if append == false {
      if let problemDocTitle = document.title, !problemDocTitle.isEmpty {
        alert.title = document.title
        titleWasAdded = true
      }
      if let problemDocDetail = document.detail, !problemDocDetail.isEmpty {
        alert.message = document.detail
        detailWasAdded = true
        if titleWasAdded {
          // now we know we set both the alert's title and message, and since
          // we are not appending (i.e. we are replacing what was on the
          // existing alert), we are done.
          return
        }
      }
    }

    // at this point either the alert's title or message could be empty.
    // Let's fill that up with what we have, either from the existing alert
    // or from the problem document.

    if alert.title?.isEmpty ?? true {
      alert.title = document.title
      titleWasAdded = true
    }

    let existingMsg: String = {
      if let alertMsg = alert.message, !alertMsg.isEmpty {
        return alertMsg + "\n"
      }
      return ""
    }()

    let docDetail = detailWasAdded ? "" : (document.detail ?? "")

    if !titleWasAdded, let docTitle = document.title, !docTitle.isEmpty, docTitle != alert.title {
      alert.message = "\(existingMsg)\(docTitle)\n\(docDetail)"
    } else {
      alert.message = "\(existingMsg)\(docDetail)"
    }
  }
  
  /**
   Presents an alert view from another given view, assuming the current
   window's root view controller is `NYPLRootTabBarController::shared`.

   - Parameters:
     - alertController: The alert to display.
     - viewController: The view from which the alert is displayed.
     - animated: Whether to animate the presentation of the alert or not.
     - completion: Callback passed on to UIViewcontroller::present().
   */
  class func presentFromViewControllerOrNil(alertController: UIAlertController?,
                                            viewController: UIViewController?,
                                            animated: Bool,
                                            completion: (() -> Void)?) {
    guard let alertController = alertController else {
      return
    }

    guard let vc = viewController else {
      NYPLRootTabBarController.shared()?.safelyPresentViewController(alertController, animated: animated, completion: completion)
      return
    }

    vc.present(alertController, animated: animated, completion: completion)
    if let msg = alertController.message {
      Log.info(#file, msg)
    }
  }

  static func presentUnrecoverableAlert(for error: String) {
    Log.error(#file, error)
    let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""),
                                  message: NSLocalizedString("An unrecoverable error occurred. Please force-quit the app and try again.", comment: "Generic error message for internal errors"),
                                  preferredStyle: .alert)
    NYPLPresentationUtils.safelyPresent(alert)
  }
}
