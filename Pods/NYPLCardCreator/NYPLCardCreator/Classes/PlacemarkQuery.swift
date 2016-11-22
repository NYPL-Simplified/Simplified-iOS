import CoreLocation
import UIKit

final class PlacemarkQuery: NSObject, CLLocationManagerDelegate {
  
  enum Result {
    case placemark(placemark: CLPlacemark)
    case errorAlertController(alertController: UIAlertController)
  }
  
  fileprivate var receivedRecentLocation = false
  fileprivate var handler: ((Result) -> Void)? = nil
  fileprivate let geocoder = CLGeocoder()
  fileprivate let locationManager = CLLocationManager()
  
  override init() {
    super.init()
    self.locationManager.delegate = self
  }

  /// Due to limitations of CoreLocation, this must only ever be called 
  /// once per `PlacemarkQuery` instance.
  func startWithHandler(_ handler: @escaping (Result) -> Void) {
    self.handler = handler
    switch CLLocationManager.authorizationStatus() {
    case .authorizedAlways:
      fallthrough
    case .authorizedWhenInUse:
      break
    case .denied:
      let alertController = UIAlertController(
        title: NSLocalizedString("Location Access Disabled",
          comment: "An alert title stating the user has disallowed the app to access the user's location"),
        message: NSLocalizedString(
          ("You must enable location access for this application " +
            "in order to sign up for a library card."),
          comment: "An alert message informing the user that location access is required"),
        preferredStyle: .alert)
      alertController.addAction(UIAlertAction(
        title: NSLocalizedString("Open Settings",
          comment: "A title for a button that will open the Settings app"),
        style: .default,
        handler: {_ in
          UIApplication.shared.openURL(URL(string:UIApplicationOpenSettingsURLString)!)
        }))
      alertController.addAction(UIAlertAction(
        title: NSLocalizedString("Cancel", comment: ""),
        style: .cancel,
        handler: nil))
      OperationQueue.main.addOperation({ 
        handler(.errorAlertController(alertController: alertController))
      })
    case .notDetermined:
      self.locationManager.requestWhenInUseAuthorization()
    case .restricted:
      let alertController = UIAlertController(
        title: NSLocalizedString("Location Access Restricted",
          comment: "An alert title stating that the user needs, but cannot enable, location access"),
        message: NSLocalizedString(
          ("Location access is required to sign up for a library card, but you do not have " +
            "permission to enable location access due to parental control settings or a hardware restriction."),
          comment: "An alert message informing the user that they need, but cannnot enable, location access"),
        preferredStyle: .alert)
      alertController.addAction(UIAlertAction(
        title: NSLocalizedString("OK", comment: ""),
        style: .default,
        handler: nil))
      OperationQueue.main.addOperation({ 
        handler(.errorAlertController(alertController: alertController))
      })
    }
  }
  
  // MARK: CLLocationManagerDelegate
  
  func locationManager(
    _ manager: CLLocationManager,
    didChangeAuthorization status: CLAuthorizationStatus)
  {
    switch status {
    case .authorizedAlways:
      fallthrough
    case .authorizedWhenInUse:
      locationManager.startUpdatingLocation()
    default:
      break
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    if self.receivedRecentLocation {
      return
    }
    
    guard let handler = self.handler else {
      return
    }
    
    // The last element is always the most recent.
    let latestLocation = locations.last!
    let fiveMinutesAgo = Date(timeIntervalSinceNow: -300)
    if latestLocation.timestamp == (latestLocation.timestamp as NSDate).laterDate(fiveMinutesAgo) {
      self.receivedRecentLocation = true
      self.locationManager.stopUpdatingLocation()
      self.geocoder.reverseGeocodeLocation(locations.last!) { (placemarks: [CLPlacemark]?, error) in
        if let placemark = placemarks?.last {
          OperationQueue.main.addOperation({ 
            handler(.placemark(placemark: placemark))
          })
        } else {
          let alertController = UIAlertController(
            title: NSLocalizedString("Could Not Determine Location",
              comment: "The title for an alert when a location cannot be determined"),
            message: NSLocalizedString("Your location could not be determined at this time. Please try again later.",
              comment: "The message for an alert when a location could not be determined"),
            preferredStyle: .alert)
          alertController.addAction(UIAlertAction(
            title: NSLocalizedString("OK", comment: ""),
            style: .default,
            handler: nil))
          OperationQueue.main.addOperation({
            handler(.errorAlertController(alertController: alertController))
          })
        }
      }
    }
  }
}
