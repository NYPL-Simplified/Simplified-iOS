//
//  SimplyE
//  Copyright © 2020 NYPL. All rights reserved.
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

  private class func keepAction(handler: @escaping () -> ()) -> UIAlertAction {
    return UIAlertAction(
      title: NSLocalizedString("Keep",
                               comment: "Button title for keeping an audiobook"),
      style: .cancel,
      handler: { _ in handler() })
  }

  private class func returnAction(handler: @escaping () -> ()) -> UIAlertAction {
    return UIAlertAction(
      title: NSLocalizedString("Return",
                               comment: "Button title for returning an audiobook"),
      style: .default,
      handler: { _ in handler() })
  }
}
