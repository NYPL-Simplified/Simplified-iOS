import XCTest
@testable import SimplyE

class NYPLAnnouncementManagerTests: XCTestCase {
  let announcementId = "test_announcement_id"
    
  override func tearDown() {
    NYPLAnnouncementManager.deletePresentedAnnouncement(id: announcementId)
  }
    
  func testShouldPresentAnnouncement() {
    XCTAssertTrue(NYPLAnnouncementManager.shouldPresentAnnouncement(id:announcementId))
  }
    
  func testAddPresentedAnnouncement() {
    NYPLAnnouncementManager.addPresentedAnnouncement(id: announcementId)
    XCTAssertFalse(NYPLAnnouncementManager.shouldPresentAnnouncement(id:announcementId))
  }
  
  func testDeletePresentedAnnouncement() {
    NYPLAnnouncementManager.deletePresentedAnnouncement(id: announcementId)
    XCTAssertTrue(NYPLAnnouncementManager.shouldPresentAnnouncement(id:announcementId))
  }
}
