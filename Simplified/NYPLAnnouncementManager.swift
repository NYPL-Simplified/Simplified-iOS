import Foundation

private let announcementKey: String = "NYPLPresentedAnnouncementKey"
private let filename: String = "NYPLPresentedAnnouncementsList"

class NYPLAnnouncementManager {
  private static var presentedAnnouncement: Set<String> = Set<String>()
    
  class func presentAnnouncements(_ announcements: [Announcement]) {
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
    
  class func shouldPresentAnnouncement(id: String) -> Bool {
    guard let filePathURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(filename),
      let filePathData = try? Data(contentsOf: filePathURL),
      let unarchived = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(filePathData),
      let presented = unarchived as? Set<String> else {
        return true
    }
    presentedAnnouncement = presented
    
    return !presentedAnnouncement.contains(id)
  }
  
  // MARK: - Write
    
  class func addPresentedAnnouncement(id: String) {
    presentedAnnouncement.insert(id)
    
    storePresentedAnnouncementToFile()
  }

  // For testing use
  class func deletePresentedAnnouncement(id: String) {
    presentedAnnouncement.remove(id)
    
    storePresentedAnnouncementToFile()
  }
    
  class private func storePresentedAnnouncementToFile() {
    guard let filePathURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(filename) else {
      // TODO: error logging
      return
    }
    
    do {
      let codedData = NSKeyedArchiver.archivedData(withRootObject: presentedAnnouncement)
      try codedData.write(to: filePathURL)
    } catch {
      // TODO: Error logging
      print(error)
    }
  }
}
