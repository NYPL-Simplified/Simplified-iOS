//
//  NYPLActivityIndicatorMessageViewController.swift
//  SimplyE
//
//  Created by Ernest Fan on 2022-06-06.
//  Copyright © 2022 NYPL. All rights reserved.
//

import UIKit

/// Display an activity indicator with a message in the center of the screen,
/// with a dimmed transparent background.
class NYPLActivityIndicatorMessageViewController: UIViewController {
  private let spacing: CGFloat = 20.0
  
  // MARK: - Life Cycle
  
  init(message: String) {
    super.init(nibName: nil, bundle: nil)
    
    self.textLabel.text = message
    self.modalPresentationStyle = .overFullScreen
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupUI()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    activityIndicator.startAnimating()
  }
  
  // MARK: - Setup
  
  private func setupUI() {
    self.view.backgroundColor = NYPLConfiguration.transparentBackgroundColor
    
    // Background of the activity indicator and text
    let backgroundView = UIView()
    backgroundView.backgroundColor = NYPLConfiguration.primaryBackgroundColor
    backgroundView.layer.cornerRadius = NYPLConfiguration.cornerRadius
    backgroundView.clipsToBounds = true
    
    backgroundView.addSubview(activityIndicator)
    activityIndicator.autoPinEdgesToSuperviewEdges(with: .init(top: spacing,
                                                               left: spacing,
                                                               bottom: spacing,
                                                               right: spacing),
                                                   excludingEdge: .trailing)
    
    backgroundView.addSubview(textLabel)
    textLabel.autoPinEdgesToSuperviewEdges(with: .init(top: spacing,
                                                       left: spacing,
                                                       bottom: spacing,
                                                       right: spacing),
                                           excludingEdge: .leading)
    
    textLabel.autoPinEdge(.leading, to: .trailing, of: activityIndicator, withOffset: spacing)
    
    /// The length of the message determines the view size when displaying the message,
    /// a longer message needs a taller and wider size and a shorter message needs a smaller size
    /// that hugs the content, without stretching all the way to the side of the screen.
    /// Since `backgroundView.intrinsicContentSize` does not give the right size,
    /// we use the calculated expanded size (within the limit of the screen size) and
    /// the compressed size to find out the best size to fit the message.
    let expandedSize = backgroundView.systemLayoutSizeFitting(.init(width: self.view.frame.width - spacing,
                                                                    height: self.view.frame.height - spacing),
                                                              withHorizontalFittingPriority: .defaultHigh,
                                                              verticalFittingPriority: .defaultHigh)

    let compressedSize = backgroundView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    backgroundView.frame.size = .init(width: min(compressedSize.width, expandedSize.width),
                                      height: max(compressedSize.height, expandedSize.height))
    
    view.addSubview(backgroundView)
    backgroundView.autoCenterInSuperview()
  }
  
  // MARK: - UI Components
  
  lazy var activityIndicator: UIActivityIndicatorView = {
    if #available(iOS 12.0, *),
       UIScreen.main.traitCollection.userInterfaceStyle == .dark {
      return UIActivityIndicatorView(style: .white)
    } else {
      return UIActivityIndicatorView(style: .gray)
    }
  }()

  lazy var textLabel: UILabel = {
    let label = UILabel(frame: .zero)
    label.textAlignment = .center
    label.textColor = NYPLConfiguration.primaryTextColor
    label.font = UIFont.customBoldFont(forTextStyle: UIFont.TextStyle.body)
    label.lineBreakMode = .byWordWrapping
    label.numberOfLines = 0
    return label
  }()
}
