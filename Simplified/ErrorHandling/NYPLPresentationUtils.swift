//
//  NYPLPresentationUtils.swift
//  SimplyE / Open eBooks
//
//  Copyright © 2020 NYPL. All rights reserved.
//

class NYPLPresentationUtils: NSObject {
  /// Presents the given view controller on top of the topmost currently
  /// displayed view controller in the current window.
  ///
  /// This function does not assume anything regarding the current view
  /// controller. In particular, it does _not_ assume that it is the
  /// `NYPLRootTabBarController::shared` instance.
  /// 
  /// If the input and topmost view controllers are both
  /// UINavigationControllers, this method bails presentation if they
  /// both contain a first view controller of the same type.
  ///
  /// - Parameters:
  ///   - vc: The view controller to be presented.
  ///   - animated: Whether to animate the presentation of not.
  ///   - completion: Completion handler to be called when the presentation ends.
  @objc class func safelyPresent(_ vc: UIViewController,
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

    if let baseNavController = base as? UINavigationController,
      let inputNavController = vc as? UINavigationController,
      baseNavController.viewControllers.count == inputNavController.viewControllers.count,
      let baseVC = baseNavController.viewControllers.first,
      let inputVC = inputNavController.viewControllers.first {

      if type(of: baseVC) == type(of: inputVC) {
        return
      }
    }

    base.present(vc, animated:animated, completion:completion)
  }
}
