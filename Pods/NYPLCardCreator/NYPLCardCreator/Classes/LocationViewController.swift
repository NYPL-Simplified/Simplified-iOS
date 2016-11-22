import UIKit

/// The second step in the card registration flow.
final class LocationViewController: UIViewController {
  
  fileprivate let configuration: CardCreatorConfiguration
  
  fileprivate let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
  fileprivate var observers: [NSObjectProtocol] = []
  fileprivate let resultLabel = UILabel()
  fileprivate var placemarkQuery: PlacemarkQuery? = nil
  fileprivate var viewDidAppearPreviously: Bool = false

  init(configuration: CardCreatorConfiguration) {
    self.configuration = configuration
    super.init(nibName: nil, bundle: nil)
  }
  
  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  deinit {
    for observer in self.observers {
      NotificationCenter.default.removeObserver(observer)
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
  
    self.title = NSLocalizedString(
      "Location Check",
      comment: "A title telling the user the app needs to check their location")
    
    let backButtonText = NSLocalizedString(
      "Location",
      comment: "A title for a button that goes to the previous 'Location Check' screen")
    let backButton = UIBarButtonItem(title: backButtonText,
                                     style: .bordered,
                                     target: nil,
                                     action: nil)
    self.navigationItem.backBarButtonItem = backButton
    
    self.view.backgroundColor = UIColor.white
    
    self.view.addSubview(self.activityIndicatorView)
    self.activityIndicatorView.autoCenterInSuperview()
    
    self.view.addSubview(self.resultLabel)
    self.resultLabel.isHidden = true
    self.resultLabel.autoPinEdgesToSuperviewMargins()
    self.resultLabel.numberOfLines = 0
    self.resultLabel.textColor = UIColor.darkGray
    self.resultLabel.textAlignment = .center
    
    self.navigationItem.rightBarButtonItem =
      UIBarButtonItem(title: NSLocalizedString("Next", comment: "A title for a button that goes to the next screen"),
                      style: .plain,
                      target: self,
                      action: #selector(didSelectNext))
    self.navigationItem.rightBarButtonItem?.isEnabled = false
   
    // We need to check again in case the user has gone to Settings to enable location services.
    self.observers.append(
      NotificationCenter.default.addObserver(
        forName: NSNotification.Name.UIApplicationDidBecomeActive,
        object: nil,
        queue: OperationQueue.main,
        using: { _ in
          if !(self.navigationItem.rightBarButtonItem?.isEnabled)! {
            // FIXME: Temporarily disabled due to being called during another location check.
            // self.checkLocation()
          }}))
  }
  
  override func viewDidAppear(_ animated: Bool) {
    if self.viewDidAppearPreviously {
      return
    }
    self.viewDidAppearPreviously = true
    self.checkLocation()
  }
  
  @objc fileprivate func didSelectNext() {
    self.navigationController?.pushViewController(
      AddressViewController(
        configuration: self.configuration,
        addressStep: .home),
      animated: true)
  }
  
  fileprivate func checkLocation() {
    self.resultLabel.isHidden = true
    self.activityIndicatorView.startAnimating()
    self.placemarkQuery = PlacemarkQuery()
    self.placemarkQuery!.startWithHandler { result in
      self.resultLabel.isHidden = false
      self.activityIndicatorView.stopAnimating()
      switch result {
      case let .errorAlertController(alertController):
        self.resultLabel.text = NSLocalizedString(
          "Your location could not be determined. Please try again later.",
          comment: "A label title informing the user that their location could not be determined")
        self.present(alertController, animated: true, completion: nil)
      case let .placemark(placemark):
        if placemark.administrativeArea == "NY" {
          self.navigationItem.rightBarButtonItem?.isEnabled = true
          self.resultLabel.text = NSLocalizedString(
            "We have successfully determined that you are in New York!",
            comment: "A label title informing the user that their location is acceptable")
        } else {
          self.resultLabel.text = NSLocalizedString(
            ("You must be in New York to sign up for a library card. "
              + " Please try to sign up again when you are in another location."),
            comment: "A label title informing the user that their location is not acceptable")
        }
      }
    }
  }
}
