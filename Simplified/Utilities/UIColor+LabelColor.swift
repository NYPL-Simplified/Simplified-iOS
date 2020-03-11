import UIKit

extension UIColor {
  @objc class public func defaultLabelColor() -> UIColor {
    if #available(iOS 13, *) {
      return UIColor.label;
    } else {
      return UIColor.black;
    }
  }
}
