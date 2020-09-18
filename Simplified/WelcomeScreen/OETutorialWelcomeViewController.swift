//
//  OETutorialWelcomeViewController.swift
//  Open eBooks
//
//  Created by Kyle Sakai.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

class OETutorialWelcomeViewController : UIViewController {
  var descriptionLabel: UILabel
  var logoImageView: UIImageView
  
  init() {
    self.descriptionLabel = UILabel.init(frame: CGRect.zero)
    self.logoImageView = UIImageView.init(image: UIImage.init(named: "app_launch_screen_image"))
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
    
    self.view.addSubview(self.logoImageView)
    
    self.descriptionLabel.font = UIFont.systemFont(ofSize: 20.0)
    self.descriptionLabel.text = NSLocalizedString("TutorialWelcomeViewControllerDescription", comment: "Welcome text for Open eBooks")
    self.descriptionLabel.textAlignment = .center
    self.descriptionLabel.numberOfLines = 0
    self.view.addSubview(self.descriptionLabel)
  }
  
  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    // Make the logo and text as wide as possible up to iPhone 6 Plus size. We cap
    // it there be able to have a reasonable text width and size.
    let minSize = min(self.view.frame.width, 414)
    let logoImageViewSize = CGSize.init(width: minSize, height: minSize)
    let descriptionLabelSize = self.descriptionLabel.sizeThatFits(CGSize.init(width: logoImageViewSize.width, height: CGFloat.greatestFiniteMagnitude))
    
    self.logoImageView.frame = CGRect.init(
      x: (self.view.frame.width - logoImageViewSize.width) / 2.0,
      y: (self.view.frame.height - (logoImageViewSize.height + descriptionLabelSize.height)) / 2.0,
      width: logoImageViewSize.width,
      height: logoImageViewSize.height
    )
    self.logoImageView.integralizeFrame()
    
    self.descriptionLabel.frame = CGRect.init(
      x: (self.view.frame.width - descriptionLabelSize.width) / 2.0,
      y: self.logoImageView.frame.maxY,
      width: descriptionLabelSize.width,
      height: descriptionLabelSize.height
    )
    self.descriptionLabel.integralizeFrame()
  }
}
