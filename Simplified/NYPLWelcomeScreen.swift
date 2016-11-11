import UIKit

/// Welcome screen for a first-time user
final class NYPLWelcomeScreen: UIViewController {
  
  override func viewDidLoad() {
    
    super.viewDidLoad()
    
    self.title = "Welcome Screen"
    self.view.backgroundColor = UIColor.redColor()
    self.view.userInteractionEnabled = true

    let gestureRecognizer = UITapGestureRecognizer(target: self, action: Selector(handleTap()))
    self.view.addGestureRecognizer(gestureRecognizer)
  }
  
  func handleTap() {
    self.dismissViewControllerAnimated(true, completion: nil)
  }

}
