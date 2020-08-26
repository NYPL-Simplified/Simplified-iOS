import Foundation

private let announcementsFilename: String = "NYPLPresentedAnnouncementsList"

class NYPLAnnouncementBusinessLogic {
  static let shared = NYPLAnnouncementBusinessLogic()

  private var presentedAnnouncements: Set<String> = Set<String>()
    
  init() {
    restorePresentedAnnouncements()
  }
    
  func presentAnnouncements(_ announcements: [Announcement]) {
    for announcement in announcements {
      if shouldPresentAnnouncement(id: announcement.id) {
        DispatchQueue.main.async {
          let vc = NYPLAnnouncementViewController(announcement: announcement)
          NYPLRootTabBarController.shared()?.safelyPresentViewController(vc, animated: true, completion: nil)
        }
      }
    }
  }
  
  // MARK: - Read
    
  fileprivate func restorePresentedAnnouncements() {
    guard let filePathURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(announcementsFilename),
      let filePathData = try? Data(contentsOf: filePathURL),
      let unarchived = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(filePathData),
      let presented = unarchived as? Set<String> else {
        return
    }
    presentedAnnouncements = presented
  }
    
  fileprivate func shouldPresentAnnouncement(id: String) -> Bool {
    return !presentedAnnouncements.contains(id)
  }
  
  // MARK: - Write
    
  /// Add presented announcement to storage
  /// No guarantees are being made about whether this is called on the main thread or not
  func addPresentedAnnouncement(id: String) {
    presentedAnnouncements.insert(id)
    
    storePresentedAnnouncementsToFile()
  }

  fileprivate func deletePresentedAnnouncement(id: String) {
    presentedAnnouncements.remove(id)
    
    storePresentedAnnouncementsToFile()
  }
    
  fileprivate func storePresentedAnnouncementsToFile() {
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
                               message: nil,
                               metadata: ["filePathURL": filePathURL,
                                          "presentedAnnouncements": presentedAnnouncements])
    }
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
