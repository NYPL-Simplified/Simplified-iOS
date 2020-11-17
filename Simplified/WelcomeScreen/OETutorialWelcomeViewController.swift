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
    
    self.view.backgroundColor = NYPLConfiguration.welcomeTutorialBackgroundColor

    self.view.addSubview(self.logoImageView)
    
    self.descriptionLabel.font = UIFont(name: NYPLConfiguration.systemFontFamilyName(),
                                        size: 20.0)
    self.descriptionLabel.text = NSLocalizedString("Welcome to Open eBooks.", comment: "Welcome text for Open eBooks")
    self.descriptionLabel.textAlignment = .center
    self.descriptionLabel.numberOfLines = 0
    self.view.addSubview(self.descriptionLabel)
  }
  
  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    // Make the logo and text as wide as possible up to iPhone 6 Plus size. We cap
    // it there be able to have a reasonable text width and size.
    let minSize = min(view.frame.width,
                      logoImageView.image?.size.width ?? 480.0)
    let logoImageViewSize = CGSize(width: minSize, height: minSize)
    let descriptionLabelSize = descriptionLabel.sizeThatFits(
      CGSize(width: logoImageViewSize.width,
             height: CGFloat.greatestFiniteMagnitude))

    self.logoImageView.frame = CGRect.init(
      x: ((view.frame.width - logoImageViewSize.width) / 2.0).rounded(),
      y: ((view.frame.height - (logoImageViewSize.height + descriptionLabelSize.height)) / 2.0).rounded(),
      width: logoImageViewSize.width,
      height: logoImageViewSize.height
    )

    self.descriptionLabel.frame = CGRect.init(
      x: (self.view.frame.width - descriptionLabelSize.width) / 2.0,
      y: self.logoImageView.frame.maxY,
      width: descriptionLabelSize.width,
      height: descriptionLabelSize.height
    )
    self.descriptionLabel.integralizeFrame()
  }
}
