import Foundation

protocol NYPLAgeCheckValidationDelegate: class {
  var minYear : Int { get }
  var currentYear : Int { get }
  var birthYearList : [Int] { get }
  var ageCheckCompleted : Bool { get set }
  
  func isValid(birthYear: Int) -> Bool
  
  func didCompleteAgeCheck(_ birthYear: Int)
  func didFailAgeCheck()
}

@objc protocol NYPLAgeCheckVerifying {
  func verifyCurrentAccountAgeRequirement(userAccountProvider: NYPLUserAccountProvider,
                                          currentLibraryAccountProvider: NYPLCurrentLibraryAccountProvider,
                                          completion: ((Bool) -> ())?) -> Void
}

@objc protocol NYPLAgeCheckChoiceStorage {
  var userPresentedAgeCheck: Bool { get set }
}

@objcMembers final class NYPLAgeCheck : NSObject, NYPLAgeCheckValidationDelegate, NYPLAgeCheckVerifying {
  
  // Members
  private let serialQueue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier!).ageCheck")
  private var handlerList = [((Bool) -> ())]()
  private var isPresenting = false
  private let ageCheckChoiceStorage: NYPLAgeCheckChoiceStorage
  var ageCheckCompleted: Bool = false
  
  let minYear: Int
  let currentYear: Int
  let birthYearList: [Int]

  init(ageCheckChoiceStorage: NYPLAgeCheckChoiceStorage) {
    self.ageCheckChoiceStorage = ageCheckChoiceStorage
    minYear = 1900
    var thisYear = abs(Calendar.current.component(.year, from: Date()))
    if thisYear < 1900 {
      // This case should be 100% impossible, but we are experiencing a few
      // strange array-out-of-bounds crashes (see OE-237). This hack obviously
      // is pretty terrible, but hopefully once we investigate the logs we'll be
      // able to determine the actual reason of this error.
      NYPLErrorLogger.logError(withCode: .localeFail,
                               summary: "Out of bounds year range attempted for Age Check",
                               metadata: [
                                "Current Date": Date(),
                                "Current NSDate": NSDate(),
                                "Current Calendar": Calendar.current.debugDescription,
                                "Calendar year from iOS": thisYear,
                                "Calendar locale": Calendar.current.locale?.debugDescription ?? "N/A",
                                "Current locale": Locale.current.debugDescription,
                                "Max year range": Calendar.current.maximumRange(of: .year) ?? "N/A"
                               ])
      thisYear = 2021
    }
    currentYear = thisYear
    birthYearList = Array(minYear...currentYear)
    
    super.init()
  }
  
  func verifyCurrentAccountAgeRequirement(userAccountProvider: NYPLUserAccountProvider,
                                          currentLibraryAccountProvider: NYPLCurrentLibraryAccountProvider,
                                          completion: ((Bool) -> ())?) {
    serialQueue.async { [weak self] in
      
      guard let accountDetails = currentLibraryAccountProvider.currentAccount?.details else {
        completion?(false)
        return
      }
      
      if userAccountProvider.needsAuth == true || accountDetails.userAboveAgeLimit {
        completion?(true)
        return
      }
      
      if !accountDetails.userAboveAgeLimit && (self?.ageCheckChoiceStorage.userPresentedAgeCheck ?? false) {
        completion?(false)
        return
      }
      
      // Queue the callback
      if let completion = completion {
        self?.handlerList.append(completion)
      }
      
      // We're already presenting the age verification, return
      if self?.isPresenting ?? false {
        return
      }
      
      let accountDetailsCompletion: ((Bool) -> ()) = { aboveAgeLimit in
        accountDetails.userAboveAgeLimit = aboveAgeLimit
      }
      self?.handlerList.append(accountDetailsCompletion)
      
      // Perform age check presentation
      self?.isPresenting = true
      self?.presentAgeVerificationView()
    }
  }
  
  fileprivate func presentAgeVerificationView() {
    DispatchQueue.main.async {
      let vc = NYPLAgeCheckViewController(ageCheckDelegate: self)
      let navigationVC = UINavigationController(rootViewController: vc)
      NYPLPresentationUtils.safelyPresent(navigationVC)
    }
  }
  
  func isValid(birthYear: Int) -> Bool {
    return birthYear >= minYear && birthYear <= currentYear
  }
  
  func didCompleteAgeCheck(_ birthYear: Int) {
    self.serialQueue.async { [weak self] in
      let aboveAgeLimit = Calendar.current.component(.year, from: Date()) - birthYear > 13
      self?.ageCheckChoiceStorage.userPresentedAgeCheck = true
      self?.isPresenting = false
      
      for handler in self?.handlerList ?? [] {
        handler(aboveAgeLimit)
      }
      self?.handlerList.removeAll()
    }
  }
  
  func didFailAgeCheck() {
    self.serialQueue.async { [weak self] in
      self?.isPresenting = false
      self?.ageCheckChoiceStorage.userPresentedAgeCheck = false
      self?.handlerList.removeAll()
    }
  }
}
