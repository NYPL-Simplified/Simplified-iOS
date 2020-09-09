//
//  NYPLPresentationUtils.swift
//  SimplyE / Open eBooks
//
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

class NYPLPresentationUtils {
  class func safelyPresent(_ vc: UIViewController,
                           animated: Bool = true,
                           completion: (()->Void)? = nil) {

    let delegate = UIApplication.shared.delegate
    guard var base = delegate?.window??.rootViewController else {
      NYPLErrorLogger.logError(withCode: .missingExpectedObject,
                               summary: "Unable to find rootViewController",
                               metadata: [
                                "DelegateIsNil" : (delegate == nil),
                                "WindowIsNil": (delegate?.window == nil)])
      return
    }
    
    while true {
      guard let topBase = base.presentedViewController else {
        break
      }
      base = topBase
    }
    base.present(vc, animated:animated, completion:completion)
  }
}
