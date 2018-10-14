import MessageUI
import UIKit

@objcMembers class ProblemReportEmail: NSObject {
  
  static let sharedInstance = ProblemReportEmail()
  
  fileprivate weak var lastPresentingViewController: UIViewController?
  
  func beginComposing(
    to emailAddress: String,
    presentingViewController: UIViewController,
    book: NYPLBook?)
  {
    guard MFMailComposeViewController.canSendMail() else {
      let alertController = UIAlertController(
        title: NSLocalizedString("NoEmailAccountSet", comment: "Alert title"),
        message: String(format: NSLocalizedString("Please contact %@ to report an issue.", comment: "Alert message"),
                        emailAddress),
        preferredStyle: .alert)
      alertController.addAction(
        UIAlertAction(title: NSLocalizedString("OK", comment: ""),
                      style: .default,
                      handler: nil))
      presentingViewController.present(alertController, animated: true)
      return
    }
    
    self.lastPresentingViewController = presentingViewController
    
    let idiom: String
    switch UIDevice.current.userInterfaceIdiom {
    case .carPlay:
      idiom = "carPlay"
    case .pad:
      idiom = "pad"
    case .phone:
      idiom = "phone"
    case .tv:
      idiom = "tv"
    case .unspecified:
      idiom = "unspecified"
    }
    let nativeHeight = UIScreen.main.nativeBounds.height
    let systemVersion = UIDevice.current.systemVersion
  
    let mailComposeViewController = MFMailComposeViewController.init()
    mailComposeViewController.mailComposeDelegate = self
    mailComposeViewController.setSubject(NYPLLocalizationNotNeeded("Problem Report"))
    mailComposeViewController.setToRecipients([emailAddress])
    let bodyWithoutBook = "\n\n---\nIdiom: \(idiom)\nHeight: \(nativeHeight)\nOS: \(systemVersion)"
    let body: String
    if let book = book {
      body = bodyWithoutBook + "\nTitle: \(book.title ?? "unknown")\nID: \(book.identifier ?? "unknown")"
    } else {
      body = bodyWithoutBook
    }
    mailComposeViewController.setMessageBody(body, isHTML: false)
    presentingViewController.present(mailComposeViewController, animated: true)
  }
}

extension ProblemReportEmail: MFMailComposeViewControllerDelegate {
  func mailComposeController(
    _ controller: MFMailComposeViewController,
    didFinishWith result: MFMailComposeResult,
    error: Error?)
  {
    controller.dismiss(animated: true, completion: nil)
    
    switch result {
    case .failed:
      if let error = error {
        let alertController = UIAlertController(
          title: NSLocalizedString("Error", comment: ""),
          message: error.localizedDescription,
          preferredStyle: .alert)
        alertController.addAction(
          UIAlertAction(
            title: NSLocalizedString("OK", comment: ""),
            style: .default,
            handler: nil))
        self.lastPresentingViewController?.present(alertController, animated: true, completion: nil)
      }
    case .sent:
      let alertController = UIAlertController(
        title: NSLocalizedString("Thank You", comment: "Alert title"),
        message: NSLocalizedString("Your report will be reviewed as soon as possible.", comment: "Alert message"),
        preferredStyle: .alert)
      alertController.addAction(
        UIAlertAction(
          title: NSLocalizedString("OK", comment: ""),
          style: .default,
          handler: nil))
      self.lastPresentingViewController?.present(alertController, animated: true, completion: nil)
    case .cancelled: fallthrough
    case .saved:
      break
    }
  }
}
