import StoreKit

@objcMembers final class NYPLAppStoreReviewPrompt: NSObject {

  /// The total numbers of times the app has checked to make a request
  private static let ReviewPromptChecksKey = "NYPLAvailabilityChecksTallyKey"

  class func presentIfAvailable()
  {
    if #available(iOS 10.3, *) {
      var count = UserDefaults.standard.value(forKey: ReviewPromptChecksKey) as? UInt ?? 0
      count += 1
      UserDefaults.standard.setValue(count, forKey: ReviewPromptChecksKey)

      // System will limit to 3 requests/yr as of 12/2018
      if (count == 1 || count == 10 || count == 25) {
        SKStoreReviewController.requestReview()
      }
    }
  }
}
