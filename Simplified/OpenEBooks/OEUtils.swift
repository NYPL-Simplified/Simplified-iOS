class OEUtils {
  class func safelyPresent(_ vc: UIViewController, animated: Bool, completion: (()->Void)?) {
    let delegate = UIApplication.shared.delegate as? OEAppDelegate
    guard var base = delegate?.window?.rootViewController else {
      // TODO: Log in bug catching framework
      Log.error("", "Could not safely present VC!")
      return
    }
    
    while true {
      guard let nBase = base.presentedViewController else {
        break
      }
      base = nBase
    }
    base.present(vc, animated:animated, completion:completion)
  }
  
  class func LocalizedString(_ s: String) -> String {
    Bundle.init(for: self).localizedString(forKey: s, value: nil, table: "OpenEBooks")
  }
}
