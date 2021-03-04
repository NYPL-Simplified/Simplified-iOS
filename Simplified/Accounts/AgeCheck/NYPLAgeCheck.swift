import Foundation

protocol NYPLAgeCheckValidationDelegate: class {
  var minYear : Int { get }
  var currentYear : Int { get }
  var birthYearList : [Int] { get }
  var ageCheckCompleted : Bool { get set }
  
  func isValid(birthYear: Int) -> Bool
  
  func ageCheckCompleted(_ birthYear: Int)
  func ageCheckFailed()
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
  let serialQueue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier!).ageCheck")
  var handlerList = [((Bool) -> ())]()
  var isPresenting = false
  var ageCheckCompleted: Bool = false
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
                                          completion: ((Bool) -> ())?) {
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
  
  func ageCheckFailed() {
    self.serialQueue.async { [weak self] in
      self?.isPresenting = false
      self?.ageCheckChoiceStorage.userPresentedAgeCheck = false
      self?.handlerList.removeAll()
    }
  }
}
