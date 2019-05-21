//
//  OPDS2CatalogsFeedTests.swift
//  SimplyETests
//
//  Created by Benjamin Anderman on 5/10/19.
//  Copyright © 2019 NYPL Labs. All rights reserved.
//

import XCTest

@testable import SimplyE

class OPDS2CatalogsFeedTests: XCTestCase {

  let testFeedUrl = Bundle.init(for: OPDS2CatalogsFeedTests.self)
    .url(forResource: "OPDS2CatalogsFeed", withExtension: "json")!
  
  let gplAuthUrl = Bundle.init(for: OPDS2CatalogsFeedTests.self)
    .url(forResource: "gpl_authentication_document", withExtension: "json")!
  let aclAuthUrl = Bundle.init(for: OPDS2CatalogsFeedTests.self)
    .url(forResource: "acl_authentication_document", withExtension: "json")!
  let dplAuthUrl = Bundle.init(for: OPDS2CatalogsFeedTests.self)
    .url(forResource: "dpl_authentication_document", withExtension: "json")!
  let nyplAuthUrl = Bundle.init(for: OPDS2CatalogsFeedTests.self)
    .url(forResource: "nypl_authentication_document", withExtension: "json")!
  
  override func setUp() {
      // Put setup code here. This method is called before the invocation of each test method in the class.
  }

  override func tearDown() {
      // Put teardown code here. This method is called after the invocation of each test method in the class.
  }

  func testLoadCatalogsFeed() {
    
    do {
      let data = try Data(contentsOf: testFeedUrl)
      let feed = try OPDS2CatalogsFeed.fromData(data)
      
      XCTAssertEqual(feed.catalogs.count, 171)
      XCTAssertEqual(feed.links.count, 4)
    } catch (let error) {
      XCTAssert(false, error.localizedDescription)
    }
  }
  
  func testInitAccountsWithPublication() {
    do {
      let data = try Data(contentsOf: testFeedUrl)
      let feed = try OPDS2CatalogsFeed.fromData(data)
      
      let gpl = Account(publication: feed.catalogs.first(where: { $0.metadata.title == "Glendora Public Library" })!, id: 1)
      let acl = Account(publication: feed.catalogs.first(where: { $0.metadata.title == "Alameda County Library" })!, id: 2)
      let dpl = Account(publication: feed.catalogs.first(where: { $0.metadata.title == "Digital Public Library of America" })!, id: 3)
      let nypl = Account(publication: feed.catalogs.first(where: { $0.metadata.title == "The New York Public Library" })!, id: 4)
      
      XCTAssertEqual(gpl.name, "Glendora Public Library")
      XCTAssertEqual(gpl.subtitle, "Connecting people to the world of ideas, information, and imagination")
      XCTAssertEqual(gpl.uuid, "urn:uuid:a7bddadc-91c7-45a3-a642-dfd137480a22")
      XCTAssertEqual(gpl.pathComponent, gpl.uuid)
      XCTAssertEqual(gpl.catalogUrl, "http://califa108.simplye-ca.org/CAGLEN/")
      XCTAssertEqual(gpl.supportEmail, "library@glendoralibrary.org")
      XCTAssertEqual(gpl.authenticationDocumentUrl, "http://califa108.simplye-ca.org/CAGLEN/authentication_document")
      XCTAssertNotNil(gpl.logo)
      
      XCTAssertEqual(acl.name, "Alameda County Library")
      XCTAssertEqual(acl.subtitle, "Infinite possibilities")
      XCTAssertEqual(acl.uuid, "urn:uuid:bce4c73c-9d0b-4eac-92e1-1405bcee9367")
      XCTAssertEqual(acl.pathComponent, acl.uuid)
      XCTAssertEqual(acl.catalogUrl, "http://acl.simplye-ca.org/CALMDA")
      XCTAssertEqual(acl.supportEmail, "simplye@aclibrary.org")
      XCTAssertEqual(acl.authenticationDocumentUrl, "http://acl.simplye-ca.org/CALMDA/authentication_document")
      XCTAssertNotNil(acl.logo)
      
      XCTAssertEqual(dpl.name, "Digital Public Library of America")
      XCTAssertEqual(dpl.subtitle, "Popular books free to download and keep, handpicked by librarians across the US.")
      XCTAssertEqual(dpl.uuid, "urn:uuid:6b849570-070f-43b4-9dcc-7ebb4bca292e")
      XCTAssertEqual(dpl.pathComponent, dpl.uuid)
      XCTAssertEqual(dpl.catalogUrl, "http://openbookshelf.dp.la/OB/groups/3")
      XCTAssertEqual(dpl.supportEmail, "ebooks@dp.la")
      XCTAssertEqual(dpl.authenticationDocumentUrl, "http://openbookshelf.dp.la/OB/authentication_document")
      XCTAssertNotNil(dpl.logo)
      
      XCTAssertEqual(nypl.name, "The New York Public Library")
      XCTAssertEqual(nypl.subtitle, "Inspiring lifelong learning, advancing knowledge, and strengthening our communities.")
      XCTAssertEqual(nypl.uuid, "urn:uuid:065c0c11-0d0f-42a3-82e4-277b18786949")
      XCTAssertEqual(nypl.pathComponent, nypl.uuid)
      XCTAssertEqual(nypl.catalogUrl, "https://circulation.librarysimplified.org/NYNYPL/")
      XCTAssertEqual(nypl.supportEmail, "simplyehelp@nypl.org")
      XCTAssertEqual(nypl.authenticationDocumentUrl, "https://circulation.librarysimplified.org/NYNYPL/authentication_document")
      XCTAssertNotNil(nypl.logo)
      
    } catch (let error) {
      XCTAssert(false, error.localizedDescription)
    }
  }
  
  func testAccountSetAuthenticationDocument() {
    do {
      let data = try Data(contentsOf: testFeedUrl)
      let feed = try OPDS2CatalogsFeed.fromData(data)
      
      let gpl = Account(publication: feed.catalogs.first(where: { $0.metadata.title == "Glendora Public Library" })!, id: 1)
      let acl = Account(publication: feed.catalogs.first(where: { $0.metadata.title == "Alameda County Library" })!, id: 2)
      let dpl = Account(publication: feed.catalogs.first(where: { $0.metadata.title == "Digital Public Library of America" })!, id: 3)
      let nypl = Account(publication: feed.catalogs.first(where: { $0.metadata.title == "The New York Public Library" })!, id: 4)
      
      gpl.authenticationDocument = try OPDS2AuthenticationDocument.fromData(try Data(contentsOf: gplAuthUrl))
      acl.authenticationDocument = try OPDS2AuthenticationDocument.fromData(try Data(contentsOf: aclAuthUrl))
      dpl.authenticationDocument = try OPDS2AuthenticationDocument.fromData(try Data(contentsOf: dplAuthUrl))
      nypl.authenticationDocument = try OPDS2AuthenticationDocument.fromData(try Data(contentsOf: nyplAuthUrl))
      
      XCTAssertEqual(gpl.needsAuth, true)
      XCTAssertEqual(gpl.supportsReservations, true)
      XCTAssertEqual(gpl.userProfileUrl, "http://califa108.simplye-ca.org/CAGLEN/patrons/me/")
      XCTAssertEqual(gpl.supportsSimplyESync, true)
      XCTAssertEqual(gpl.cardCreatorUrl, "https://catalog.ci.glendora.ca.us/polaris/patronaccount/selfregister.aspx?ctx=3.1033.0.0.1")
      XCTAssertEqual(gpl.supportsCardCreator, false)
      XCTAssertEqual(gpl.getLicenseURL(.privacyPolicy), URL(string: "http://califa.org/privacy-policy"))
      XCTAssertEqual(gpl.getLicenseURL(.eula), URL(string: "http://www.librarysimplified.org/EULA.html"))
      XCTAssertEqual(gpl.getLicenseURL(.contentLicenses), URL(string: "http://califa.org/third-party-content"))
      XCTAssertEqual(gpl.getLicenseURL(.acknowledgements), nil)
      XCTAssertEqual(gpl.mainColor, "blue")
      XCTAssertEqual(gpl.supportsBarcodeScanner, true)
      XCTAssertEqual(gpl.supportsBarcodeDisplay, true)
      XCTAssertEqual(gpl.patronIDKeyboard, .numeric)
      XCTAssertEqual(gpl.pinKeyboard, .numeric)
      XCTAssertEqual(gpl.authPasscodeLength, 99)
      
      XCTAssertEqual(acl.needsAuth, true)
      XCTAssertEqual(acl.supportsReservations, true)
      XCTAssertEqual(acl.userProfileUrl, "http://acl.simplye-ca.org/CALMDA/patrons/me/")
      XCTAssertEqual(acl.supportsSimplyESync, true)
      XCTAssertEqual(acl.cardCreatorUrl, nil)
      XCTAssertEqual(acl.supportsCardCreator, false)
      XCTAssertEqual(acl.getLicenseURL(.privacyPolicy), URL(string: "http://califa.org/privacy-policy"))
      XCTAssertEqual(acl.getLicenseURL(.eula), URL(string: "http://www.librarysimplified.org/EULA.html"))
      XCTAssertEqual(acl.getLicenseURL(.contentLicenses), URL(string: "http://guides.aclibrary.org/TAC"))
      XCTAssertEqual(acl.getLicenseURL(.acknowledgements), nil)
      XCTAssertEqual(acl.mainColor, "lightblue")
      XCTAssertEqual(acl.supportsBarcodeScanner, false)
      XCTAssertEqual(acl.supportsBarcodeDisplay, false)
      XCTAssertEqual(acl.patronIDKeyboard, .numeric)
      XCTAssertEqual(acl.pinKeyboard, .standard)
      XCTAssertEqual(acl.authPasscodeLength, 99)
      
      XCTAssertEqual(dpl.needsAuth, false)
      XCTAssertEqual(dpl.supportsReservations, false)
      XCTAssertEqual(dpl.userProfileUrl, "http://openbookshelf.dp.la/OB/patrons/me/")
      XCTAssertEqual(dpl.supportsSimplyESync, true)
      XCTAssertEqual(dpl.cardCreatorUrl, nil)
      XCTAssertEqual(dpl.supportsCardCreator, false)
      XCTAssertEqual(dpl.getLicenseURL(.privacyPolicy), nil)
      XCTAssertEqual(dpl.getLicenseURL(.eula), nil)
      XCTAssertEqual(dpl.getLicenseURL(.contentLicenses), nil)
      XCTAssertEqual(dpl.getLicenseURL(.acknowledgements), nil)
      XCTAssertEqual(dpl.mainColor, "cyan")
      XCTAssertEqual(dpl.supportsBarcodeScanner, false)
      XCTAssertEqual(dpl.supportsBarcodeDisplay, false)
      XCTAssertEqual(dpl.patronIDKeyboard, .standard)
      XCTAssertEqual(dpl.pinKeyboard, .standard)
      XCTAssertEqual(dpl.authPasscodeLength, 99)
      
      XCTAssertEqual(nypl.needsAuth, true)
      XCTAssertEqual(nypl.supportsReservations, true)
      XCTAssertEqual(nypl.userProfileUrl, "https://circulation.librarysimplified.org/NYNYPL/patrons/me/")
      XCTAssertEqual(nypl.supportsSimplyESync, true)
      XCTAssertEqual(nypl.cardCreatorUrl, nil)
      XCTAssertEqual(nypl.supportsCardCreator, false)
      XCTAssertEqual(nypl.getLicenseURL(.privacyPolicy), URL(string: "http://www.librarysimplified.org/privacypolicy.html"))
      XCTAssertEqual(nypl.getLicenseURL(.eula), URL(string: "http://www.librarysimplified.org/EULA.html"))
      XCTAssertEqual(nypl.getLicenseURL(.contentLicenses), URL(string: "http://www.librarysimplified.org/license.html"))
      XCTAssertEqual(nypl.getLicenseURL(.acknowledgements), URL(string: "http://www.librarysimplified.org/acknowledgments.html"))
      XCTAssertEqual(nypl.mainColor, "red")
      XCTAssertEqual(nypl.supportsBarcodeScanner, true)
      XCTAssertEqual(nypl.supportsBarcodeDisplay, true)
      XCTAssertEqual(nypl.patronIDKeyboard, .standard)
      XCTAssertEqual(nypl.pinKeyboard, .numeric)
      XCTAssertEqual(nypl.authPasscodeLength, 4)
      
    } catch (let error) {
      XCTAssert(false, error.localizedDescription)
    }
  }

}
