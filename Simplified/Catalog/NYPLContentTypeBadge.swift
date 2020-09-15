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
    backgroundColor = NYPLConfiguration.mainColor()
    contentMode = .scaleAspectFit
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
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
