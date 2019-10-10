class OETutorialEligibilityViewController : UIViewController {
  var descriptionLabel: UILabel
  
  init() {
    self.descriptionLabel = UILabel.init(frame: CGRect.zero)
    super.init(nibName: nil, bundle: nil)
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: UIViewController
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if #available(iOS 13.0, *) {
      self.view.backgroundColor = .systemBackground
    } else {
      self.view.backgroundColor = .white
    }
    
    self.descriptionLabel = UILabel.init(frame: CGRect.zero)
    self.descriptionLabel.font = UIFont.systemFont(ofSize: 20.0)
    self.descriptionLabel.text = OEUtils.LocalizedString("TutorialEligibilityViewControllerDescription")
    self.descriptionLabel.textAlignment = .center
    self.descriptionLabel.numberOfLines = 0
    self.view.addSubview(self.descriptionLabel)
  }
  
  override func viewWillLayoutSubviews() {
    let minSize = (min(self.view.frame.width, 414)) - 20
    let descriptionLabelSize = self.descriptionLabel.sizeThatFits(CGSize.init(width: minSize, height: CGFloat.greatestFiniteMagnitude))
    self.descriptionLabel.frame = CGRect.init(x: 0, y: 0, width: descriptionLabelSize.width, height: descriptionLabelSize.height)
    self.descriptionLabel.centerInSuperview()
    self.descriptionLabel.integralizeFrame()
  }
}
