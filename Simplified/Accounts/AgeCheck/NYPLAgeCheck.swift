import Foundation

protocol NYPLAgeCheckDelegate: class {
  var minYear : Int { get }
  var currentYear : Int { get }
  var birthYearList : [Int] { get }
  
  func isValid(birthYear: Int) -> Bool
  
  func ageCheckCompleted(_ birthYear: Int)
  func ageCheckFailed()
}

@objc protocol NYPLAgeCheckVerification {
  func verifyCurrentAccountAgeRequirement(userAccountProvider: NYPLUserAccountProvider,
                                          currentLibraryAccountProvider: NYPLCurrentLibraryAccountProvider,
                                          _ completion: ((Bool) -> ())?) -> Void
}

@objcMembers final class NYPLAgeCheck : NSObject, NYPLAgeCheckDelegate, NYPLAgeCheckVerification {

  // Members
  let serialQueue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier!).ageCheck")
  var handlerList = [((Bool) -> ())]()
  var isPresenting = false
  let ageCheckChoiceStorage: NYPLAgeCheckChoiceStorage
  
  var minYear: Int = 1900
  
  var currentYear: Int = Calendar.current.component(.year, from: Date())
  
  var birthYearList: [Int] {
    return Array(minYear...currentYear)
  }

  init(ageCheckChoiceStorage: NYPLAgeCheckChoiceStorage) {
    self.ageCheckChoiceStorage = ageCheckChoiceStorage
    
    super.init()
  }
  
  func verifyCurrentAccountAgeRequirement(userAccountProvider: NYPLUserAccountProvider,
                                          currentLibraryAccountProvider: NYPLCurrentLibraryAccountProvider,
                                          _ completion: ((Bool) -> ())?) {
    serialQueue.async {
      
      guard let accountDetails = currentLibraryAccountProvider.currentAccount?.details else {
        completion?(false)
        return
      }
      
      if userAccountProvider.needsAuth == true || accountDetails.userAboveAgeLimit {
        completion?(true)
        return
      }
      
      if !accountDetails.userAboveAgeLimit && self.ageCheckChoiceStorage.userPresentedAgeCheck {
        completion?(false)
        return
      }
      
      // Queue the callback
      if let completion = completion {
        self.handlerList.append(completion)
      }
      
      // We're already presenting the age verification, return
      if self.isPresenting {
        return
      }
      
      let accountDetailsCompletion: ((Bool) -> ()) = { aboveAgeLimit in
        accountDetails.userAboveAgeLimit = aboveAgeLimit
      }
      self.handlerList.append(accountDetailsCompletion)
      
      // Perform age check presentation
      self.isPresenting = true
      self.presentAgeVerificationView()
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
  
  func ageCheckCompleted(_ birthYear: Int) {
    let aboveAgeLimit = Calendar.current.component(.year, from: Date()) - birthYear > 13
    ageCheckChoiceStorage.userPresentedAgeCheck = true
    self.isPresenting = false
    
    self.serialQueue.async { [weak self] in
      for handler in self?.handlerList ?? [] {
        handler(aboveAgeLimit)
      }
      self?.handlerList.removeAll()
    }
  }
  
  func ageCheckFailed() {
    self.isPresenting = false
    ageCheckChoiceStorage.userPresentedAgeCheck = false
    self.serialQueue.async { [weak self] in
      self?.handlerList.removeAll()
    }
  }
}
