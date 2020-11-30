//
//  OETutorialWelcomeViewController.swift
//  Open eBooks
//
//  Created by Kyle Sakai.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

class OETutorialWelcomeViewController : UIViewController {
  let padding: CGFloat = 30.0

  var descriptionLabel: UILabel
  var logoImageView: UIImageView
  
  init() {
    self.descriptionLabel = UILabel.init(frame: CGRect.zero)
    self.logoImageView = UIImageView(image: UIImage(named: "Logo"))
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

    self.descriptionLabel.font = NYPLConfiguration.welcomeScreenFont()
    self.descriptionLabel.text = NSLocalizedString("Welcome to Open eBooks",
                                                   comment: "Welcome text")
    self.descriptionLabel.textAlignment = .center
    self.descriptionLabel.numberOfLines = 0
    self.view.addSubview(self.descriptionLabel)
  }
  
  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()

    // get actual asset size to keep ratio intact when resizing
    let logoAssetWidth = logoImageView.image?.size.width ?? 331.0
    let logoAssetHeight = logoImageView.image?.size.height ?? 241.0

    // since we have a vector image, use half the screen similarly as launch img
    let logoWidth = view.frame.width / 2
    let logoHeight = logoWidth * logoAssetHeight / logoAssetWidth
    let logoImageViewSize = CGSize(width: logoWidth, height: logoHeight)

    let descriptionLabelSize = descriptionLabel.sizeThatFits(
      CGSize(width: view.frame.width - padding * 2,
             height: CGFloat.greatestFiniteMagnitude))

    self.logoImageView.frame = CGRect.init(
      x: ((view.frame.width - logoImageViewSize.width) / 2.0).rounded(),
      y: ((view.frame.height - (logoImageViewSize.height + descriptionLabelSize.height)) / 2.0).rounded(),
      width: logoImageViewSize.width,
      height: logoImageViewSize.height
    )
    self.logoImageView.integralizeFrame()

    self.descriptionLabel.frame = CGRect.init(
      x: (self.view.frame.width - descriptionLabelSize.width) / 2.0,
      y: self.logoImageView.frame.maxY + padding,
      width: descriptionLabelSize.width,
      height: descriptionLabelSize.height
    )
    self.descriptionLabel.integralizeFrame()
  }
}
