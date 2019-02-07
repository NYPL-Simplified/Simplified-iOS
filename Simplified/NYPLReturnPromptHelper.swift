import Bugsnag

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
        logKeepAction()
        handler()
    })
  }

  fileprivate class func returnAction(handler: @escaping () -> ()) -> UIAlertAction
  {
    return UIAlertAction(
      title: NSLocalizedString("Return", comment: ""),
      style: .default,
      handler: { action in
        logReturnAction()
        handler()
    })
  }
}

fileprivate func logKeepAction()
{
  let keepException = NSException(name:NSExceptionName(rawValue: "NYPLAudiobookKeepException"),
                                  reason:"User chose to keep the audiobook, and not return it.",
                                  userInfo:nil)
  Bugsnag.notify(keepException)
}

fileprivate func logReturnAction()
{
  let returnException = NSException(name:NSExceptionName(rawValue: "NYPLAudiobookReturnException"),
                                    reason:"User chose to return the Audiobook early.",
                                    userInfo:nil)
  Bugsnag.notify(returnException)
}
