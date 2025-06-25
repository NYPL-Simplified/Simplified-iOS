import UIKit

@objcMembers class DeprecationView : UIView {
 
  @available(*, unavailable)
  private override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  init(origin: CGPoint, width: CGFloat) {
    let toolbarHeight = CGFloat(80);
    
    super.init(frame: CGRect(x: origin.x, y: origin.y, width: width, height: toolbarHeight))

    let linkButton = UIButton(type: .custom)
      linkButton.backgroundColor = NYPLConfiguration.blueBackgroundColor
      linkButton.setTitle("Please note: SimplyE will discontinue service in late August 2025. Learn more: nypl.org/ebookhelp", for: .normal)
      linkButton.setTitleColor(.white, for: .normal)
      linkButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .regular)
      linkButton.titleLabel?.numberOfLines = 0
      linkButton.contentEdgeInsets = UIEdgeInsets(top: 20, left: 30, bottom: 20, right: 30)
      addSubview(linkButton)
      linkButton.translatesAutoresizingMaskIntoConstraints = false
      linkButton.addTarget(self, action: #selector(myButtonTapped(_:)), for: .touchUpInside)
      
  }
    
  @IBAction func myButtonTapped(_ sender: Any) {
    if let url = URL(string: "https://www.nypl.org/ebookhelp") {
        UIApplication.shared.open(url)
    } else {
        print("Invalid URL")
    }
  }

}
