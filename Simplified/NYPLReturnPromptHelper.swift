//
//  SimplyE
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

@objcMembers final class NYPLReturnPromptHelper: NSObject {

  class func audiobookPrompt(completion:@escaping (_ returnWasChosen:Bool)->()) -> UIAlertController
  {
    let title = NSLocalizedString("Your Audiobook Has Finished", comment: "")
    let message = NSLocalizedString("Would you like to return it?", comment: "")
    let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
    let keepBook = keepAction {
      completion(false)
    }
    let returnBook = returnAction {
      completion(true)
    }
    alert.addAction(keepBook)
    alert.addAction(returnBook)
    return alert
  }

  fileprivate class func keepAction(handler: @escaping () -> ()) -> UIAlertAction
  {
    return UIAlertAction(
      title: NSLocalizedString("Keep", comment: ""),
      style: .cancel,
      handler: { action in
        NYPLErrorLogger.logAudiobookInfoEvent(
          message: "User chose to keep the audiobook, and not return it.")
        handler()
    })
  }

  fileprivate class func returnAction(handler: @escaping () -> ()) -> UIAlertAction
  {
    return UIAlertAction(
      title: NSLocalizedString("Return", comment: ""),
      style: .default,
      handler: { action in
        NYPLErrorLogger.logAudiobookInfoEvent(
          message: "User chose to return the Audiobook early.")
        handler()
    })
  }
}
