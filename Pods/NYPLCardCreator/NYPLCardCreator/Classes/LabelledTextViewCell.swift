import PureLayout
import UIKit

/// A subclass of `UITableViewCell` with a label on the left side and a text field
/// on the right. Metrics are identical to those often used by Apple.
final class LabelledTextViewCell: UITableViewCell
{
  let label: UILabel
  let textField: UITextField
  
  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    self.label = UILabel()
    self.textField = UITextField()
    
    super.init(style: .default, reuseIdentifier: reuseIdentifier)
    
    if ProcessInfo().isOperatingSystemAtLeast(
      OperatingSystemVersion(majorVersion: 9, minorVersion: 0, patchVersion: 0))
    {
      self.label.autoSetDimension(.width, toSize: 100)
    } else {
      // The above method does not work correctly on iOS 8 so we do this instead.
      self.label.text = "Temporary"
      let labelSize = self.label.sizeThatFits(CGSize(width: 100, height: CGFloat.greatestFiniteMagnitude))
      self.label.frame = CGRect(x: 0, y: 0, width: labelSize.width, height: labelSize.height)
      self.label.text = nil
    }
    
    self.textField.leftView = label
    self.textField.leftViewMode = .always
    self.addSubview(self.textField)
    self.textField.autoPinEdge(toSuperviewEdge: .left, withInset: 15)
    self.textField.autoPinEdge(toSuperviewEdge: .right, withInset: 15)
    self.textField.autoCenterInSuperview()
  }
  
  convenience init(title: String?, placeholder: String?) {
    self.init(style: .default, reuseIdentifier: nil)
    self.label.text = title
    self.textField.placeholder = placeholder
  }
  
  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
