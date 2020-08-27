import UIKit

/// Announcement modal view controller
class NYPLAnnouncementViewController: UIViewController {

    let announcement: Announcement
    
    init(announcement: Announcement) {
      self.announcement = announcement
      super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
      super.viewDidLoad()
        
      setupView()
    }
    
    // MARK: - UI Setup
    
    func setupView() {
        view.backgroundColor = .white
        
        let dismissBtn = UIButton(type: .system)
        dismissBtn.setTitle("Dismiss", for: .normal)
        dismissBtn.addTarget(self, action: #selector(dismissView), for: .touchUpInside)
        view.addSubview(dismissBtn)
        
        dismissBtn.autoSetDimensions(to: CGSize(width: view.bounds.size.width, height: 30))
        dismissBtn.autoAlignAxis(toSuperviewAxis: .vertical)
        dismissBtn.autoPinEdge(toSuperviewSafeArea: .bottom)
        
        let textView = UITextView()
        textView.text = announcement.content
        textView.isScrollEnabled = true
        textView.isUserInteractionEnabled = true
        view.addSubview(textView)
        
        textView.autoPinEdge(toSuperviewSafeArea: .top, withInset: 12)
        textView.autoPinEdge(toSuperviewSafeArea: .left, withInset: 12)
        textView.autoPinEdge(toSuperviewSafeArea: .right, withInset: 12)
        textView.autoPinEdge(.bottom, to: .top, of: dismissBtn, withOffset: -10)
    }
    
    // MARK: Dismiss
    
    @objc func dismissView() {
      self.dismiss(animated: true) {
        NYPLAnnouncementBusinessLogic.shared.addPresentedAnnouncement(id: self.announcement.id)
      }
    }
}
