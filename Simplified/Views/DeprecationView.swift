import UIKit
import WebKit

@objcMembers class DeprecationView : UIView {

    var linkButton: UIButton = {
        let linkButton = UIButton(type: .custom)
        linkButton.backgroundColor = NYPLConfiguration.blueBackgroundColor
        linkButton.setTitle("Please note: SimplyE will discontinue service in late August 2025. Learn more: nypl.org/ebookhelp", for: .normal)
        linkButton.setTitleColor(.white, for: .normal)
        linkButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        linkButton.titleLabel?.textAlignment = .center
        linkButton.titleLabel?.numberOfLines = 0
        linkButton.contentEdgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        linkButton.translatesAutoresizingMaskIntoConstraints = false
        linkButton.isUserInteractionEnabled = true
        return linkButton
    }()
 
  @available(*, unavailable)
  private override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  init(origin: CGPoint, width: CGFloat) {
      super.init(frame: CGRect(x: origin.x, y: origin.y, width: width, height: linkButton.frame.size.height))

    addSubview(linkButton)
    linkButton.addTarget(self, action: #selector(myButtonTapped), for: .touchUpInside)
    linkButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
    linkButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor).isActive = true
    linkButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor).isActive = true
    linkButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor).isActive = true
  }
    
  @objc func myButtonTapped() {
    if let url = URL(string: "https://www.nypl.org/ebookhelp") {
        UIApplication.shared.open(url)
    } else {
        print("Invalid URL")
    }
  }

}
