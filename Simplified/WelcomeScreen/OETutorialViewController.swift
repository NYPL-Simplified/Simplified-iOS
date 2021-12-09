//
//  OETutorialViewController.swift
//  Open eBooks
//
//  Created by Kyle Sakai.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

class OETutorialViewController : UIPageViewController, UIPageViewControllerDataSource {
  private var viewControllersList = [UIViewController]()
  
  init() {
    super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK:- UIViewController
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.dataSource = self
    
    self.view.backgroundColor = NYPLConfiguration.welcomeTutorialBackgroundColor
    
    updateColors()
    
    self.viewControllersList = [
      OETutorialWelcomeViewController(),
      OETutorialChoiceViewController()
    ]
    
    self.setViewControllers([self.viewControllersList[0]],
                            direction: .forward,
                            animated: true,
                            completion: nil)
  }
  
  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    if #available(iOS 12.0, *),
       let previousTraitCollection = previousTraitCollection,
       UIScreen.main.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle
    {
      updateColors()
    }
  }
  
  private func updateColors() {
    let pageControl = UIPageControl.appearance(whenContainedInInstancesOf: [OETutorialViewController.self])
    pageControl.pageIndicatorTintColor = .lightGray
    pageControl.currentPageIndicatorTintColor = NYPLConfiguration.mainColor()
    pageControl.backgroundColor = .clear
  }
  
  // MARK: UIPageViewControllerDataSource
  
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    let idx = self.viewControllersList.firstIndex(of: viewController) ?? 0
    if idx < 1 {
      return nil
    } else {
      return self.viewControllersList[idx - 1]
    }
  }
  
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    let idx = self.viewControllersList.firstIndex(of: viewController) ?? Int.max
    if idx >= self.viewControllersList.count - 1 {
      return nil
    } else {
      return self.viewControllersList[idx + 1]
    }
  }
  
  func presentationCount(for pageViewController: UIPageViewController) -> Int {
    return self.viewControllersList.count
  }
  
  func presentationIndex(for pageViewController: UIPageViewController) -> Int {
    guard let presentedVC = self.presentedViewController else {
      Log.error("UIPageViewController", "Cannot find presented view controller")
      return 0
    }
    let idx = self.viewControllersList.firstIndex(of: presentedVC)
    if idx == nil {
      Log.error("UIPageViewController", "Cannot find index for view controller")
    }
    return idx ?? 0
  }
  
  // MARK: -
  
  func welcomeScreenCompletionHandler(_ account: Account) {
    NYPLSettings.shared.userHasSeenWelcomeScreen = true
    NYPLBookRegistry.shared().save()
    AccountsManager.shared.currentAccount = account
    NYPLRootTabBarController.shared()?.catalogNavigationController.updateFeedAndRegistryOnAccountChange()
    
    self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
    self.dismiss(animated: true, completion: nil)
    let appDelegate = UIApplication.shared.delegate
    appDelegate?.window??.rootViewController = NYPLRootTabBarController.shared()
  }
}
