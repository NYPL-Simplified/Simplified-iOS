import UIKit

/// This class presents a `UIActivityIndicatorView` adjacent to a `UILabel`. It is meant
/// to be used as a title view when the UI is disabled due to an action in progress (as
/// demonstrated in Apple's Settings application).
final class ActivityTitleView: UIView {
  
  init(title: String) {
    super.init(frame: CGRect.zero)
    
    let padding: CGFloat = 5.0
    
    let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    activityIndicatorView.startAnimating()
    self.addSubview(activityIndicatorView)
    activityIndicatorView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .right)
    
    let titleLabel = UILabel()
    titleLabel.text = title
    titleLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
    titleLabel.sizeToFit()
    self.addSubview(titleLabel)
    titleLabel.autoPinEdge(.left, to: .right, of: activityIndicatorView, withOffset: padding)
    titleLabel.autoPinEdge(toSuperviewEdge: .top)
    titleLabel.autoPinEdge(toSuperviewEdge: .bottom)
    
    // This view is used to keep the title label centered as in Apple's Settings application.
    let rightPaddingView = UIView(frame:activityIndicatorView.bounds)
    self.addSubview(rightPaddingView)
    rightPaddingView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .left)
    rightPaddingView.autoPinEdge(.left, to: .right, of: titleLabel, withOffset: padding)
    
    self.frame.size = self.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
