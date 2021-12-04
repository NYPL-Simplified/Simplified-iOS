import UIKit

final class NYPLContentBadgeImageView: UIImageView {

  @objc enum NYPLBadgeImage: Int {
    case audiobook
    case ebook

    func assetName() -> String {
      switch self {
      case .audiobook:
        return "AudiobookBadge"
      case .ebook:
        fatalError("No asset yet")
      }
    }
  }

  @objc required init(badgeImage: NYPLBadgeImage) {
    super.init(image: UIImage(named: badgeImage.assetName()))
    updateColors()
    
    contentMode = .scaleAspectFit
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
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
    if #available(iOS 12.0, *),
       UIScreen.main.traitCollection.userInterfaceStyle == .dark {
      backgroundColor = NYPLConfiguration.primaryBackgroundColor
    } else {
      backgroundColor = NYPLConfiguration.mainColor()
    }
  }

  @objc class func pin(badge: UIImageView, toView view: UIView) {
    if (badge.superview == nil) {
      view.addSubview(badge)
    }
    badge.autoSetDimensions(to: CGSize(width: 24, height: 24))
    badge.autoPinEdge(.trailing, to: .trailing, of: view)
    badge.autoPinEdge(.bottom, to: .bottom, of: view)
  }
}
