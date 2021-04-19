import Foundation

private let announcementsFilename: String = "NYPLPresentedAnnouncementsList"

/// This class is not thread safe
class NYPLAnnouncementBusinessLogic {
  static let shared = NYPLAnnouncementBusinessLogic()

  private var presentedAnnouncements: Set<String> = Set<String>()
    
  init() {
    restorePresentedAnnouncements()
  }
    
  /// Present the announcement in a view controller
  /// This method should be called on main thread
  func presentAnnouncements(_ announcements: [Announcement]) {
    let presentableAnnouncements = announcements.filter {
      shouldPresentAnnouncement(id: $0.id)
    }
    guard let alert = self.alert(announcements: presentableAnnouncements) else {
      return
    }
    NYPLRootTabBarController.shared()?.safelyPresentViewController(alert, animated: true, completion: nil)
  }
  
  // MARK: - Read
    
  private func restorePresentedAnnouncements() {
    guard let filePathURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(announcementsFilename),
      let filePathData = try? Data(contentsOf: filePathURL),
      let unarchived = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(filePathData),
      let presented = unarchived as? Set<String> else {
        return
    }
    presentedAnnouncements = presented
  }
    
  private func shouldPresentAnnouncement(id: String) -> Bool {
    return !presentedAnnouncements.contains(id)
  }
  
  // MARK: - Write

  func addPresentedAnnouncement(id: String) {
    presentedAnnouncements.insert(id)
    
    storePresentedAnnouncementsToFile()
  }

  private func deletePresentedAnnouncement(id: String) {
    presentedAnnouncements.remove(id)
    
    storePresentedAnnouncementsToFile()
  }
    
  private func storePresentedAnnouncementsToFile() {
    guard let filePathURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(announcementsFilename) else {
        NYPLErrorLogger.logError(withCode: .directoryURLCreateFail, summary: "Unable to create directory URL for storing presented announcements")
      return
    }
    
    do {
      let codedData = NSKeyedArchiver.archivedData(withRootObject: presentedAnnouncements)
      try codedData.write(to: filePathURL)
    } catch {
      NYPLErrorLogger.logError(error,
                               summary: "Fail to write Presented Announcements file to local storage",
                               metadata: ["filePathURL": filePathURL,
                                          "presentedAnnouncements": presentedAnnouncements])
    }
  }
  
  // MARK: - Helper
  
  /**
  Generates an alert view that presents another alert when being dismissed
  - Parameter announcements: an array of announcements that goes into alert message.
  - Returns: The alert controller to be presented.
  */
  private func alert(announcements: [Announcement]) -> UIAlertController? {
    let title = NSLocalizedString("Announcement", comment: "")
    var currentAlert: UIAlertController? = nil
    
    let alerts = announcements.map {
      UIAlertController.init(title: title, message: $0.content, preferredStyle: .alert)
    }
    
    // Present another alert when the current alert is being dismiss
    // Add the presented announcement to the presentedAnnouncement document
    for (i, alert) in alerts.enumerated() {
      if i > 0 {
        let action = UIAlertAction.init(title: NSLocalizedString("OK", comment: ""),
                                        style: .default) { [weak self] _ in
          NYPLRootTabBarController.shared()?.safelyPresentViewController(alert, animated: true, completion: nil)
          self?.addPresentedAnnouncement(id: announcements[i - 1].id)
        }
        currentAlert?.addAction(action)
      }
      currentAlert = alert
    }
    
    // Add dismiss button to the last announcement
    if let last = announcements.last {
      currentAlert?.addAction(UIAlertAction.init(title: NSLocalizedString("OK", comment: ""), style: .default) { [weak self] _ in
        self?.addPresentedAnnouncement(id: last.id)
      })
    }
    
    return alerts.first
  }
}

// Wrapper for unit testing
extension NYPLAnnouncementBusinessLogic {
  func testing_shouldPresentAnnouncement(id: String) -> Bool {
    shouldPresentAnnouncement(id: id)
  }
    
  func testing_deletePresentedAnnouncement(id: String) {
    deletePresentedAnnouncement(id: id)
  }
}
