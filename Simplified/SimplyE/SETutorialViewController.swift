class SETutorialViewController : UIPageViewController, UIPageViewControllerDataSource {
  private var views: [UIViewController]
  
  init() {
    self.views = []
    super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: UIViewController
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.dataSource = self
    
    if #available(iOS 13.0, *) {
      self.view.backgroundColor = .systemBackground
    } else {
      self.view.backgroundColor = .white
    }
    
    let pageControl = UIPageControl.appearance(whenContainedInInstancesOf: [SETutorialViewController.self])
    pageControl.pageIndicatorTintColor = .black
    pageControl.currentPageIndicatorTintColor = NYPLConfiguration.shared.mainColor
    pageControl.backgroundColor = .white
    
    self.views = [
      SETutorialChoiceViewController.init(completion: { (account) in
        if !Thread.isMainThread {
          DispatchQueue.main.async {
            self.welcomeScreenCompletionHandler(account)
          }
        } else {
          self.welcomeScreenCompletionHandler(account)
        }
      })
    ]
    
    self.setViewControllers(self.views, direction: .forward, animated: true, completion: nil)
  }
  
  // MARK: UIPageViewControllerDataSource
  
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    let idx = self.views.index(of: viewController) ?? 0
    if idx < 1 {
      return nil
    } else {
      return self.views[idx - 1]
    }
  }
  
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    let idx = self.views.index(of: viewController) ?? Int.max
    if idx >= self.views.count - 1 {
      return nil
    } else {
      return self.views[idx + 1]
    }
  }
  
  // MARK: -
  
  func welcomeScreenCompletionHandler(_ account: Account) {
    NYPLSettings.shared.userHasSeenWelcomeScreen = true
    NYPLBookRegistry.shared()?.save()
    AccountsManager.shared.currentAccount = account
    NYPLRootTabBarController.shared()?.catalogNavigationController.updateFeedAndRegistryOnAccountChange()
    
    self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
    self.dismiss(animated: true, completion: nil)
    let appDelegate = UIApplication.shared.delegate as? NYPLAppDelegate
    appDelegate?.window?.rootViewController = NYPLRootTabBarController.shared()
  }
}
