//
//  OPDS2LibraryRegistryFeedTests.swift
//  SimplyETests
//
//  Created by Benjamin Anderman on 5/10/19.
//  Copyright © 2019 NYPL Labs. All rights reserved.
//

import XCTest

@testable import SimplyE

class OPDS2LibraryRegistryFeedTests: XCTestCase {

  let testFeedUrl = Bundle.init(for: OPDS2LibraryRegistryFeedTests.self)
    .url(forResource: "OPDS2LibraryRegistryFeed", withExtension: "json")!
  
  let bplAuthUrl = Bundle.init(for: OPDS2LibraryRegistryFeedTests.self)
    .url(forResource: "bpl_authentication_document", withExtension: "json")!
  let gplAuthUrl = Bundle.init(for: OPDS2LibraryRegistryFeedTests.self)
    .url(forResource: "gpl_authentication_document", withExtension: "json")!
  let aclAuthUrl = Bundle.init(for: OPDS2LibraryRegistryFeedTests.self)
    .url(forResource: "acl_authentication_document", withExtension: "json")!
  let dplAuthUrl = Bundle.init(for: OPDS2LibraryRegistryFeedTests.self)
    .url(forResource: "dpl_authentication_document", withExtension: "json")!
  let nyplAuthUrl = Bundle.init(for: OPDS2LibraryRegistryFeedTests.self)
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
      let feed = try OPDS2LibraryRegistryFeed.fromData(data)
      
      XCTAssertEqual(feed.catalogs.count, 6)
      XCTAssertEqual(feed.links.count, 1)
    } catch (let error) {
      XCTAssert(false, error.localizedDescription)
    }
  }
  
  // This test will take a while, and shouldn't normally be run because it relies on the network
  func disabledTestLoadAllAuthenticationDocuments() {
    var errors: [String] = []
    do {
      let data = try Data(contentsOf: testFeedUrl)
      let feed = try OPDS2LibraryRegistryFeed.fromData(data)
      
      XCTAssertEqual(feed.catalogs.count, 6)
      XCTAssertEqual(feed.links.count, 1)
      
      for publication in feed.catalogs {
        do {
          let authDocumentUrl = publication.links.first(where: { $0.type == "application/vnd.opds.authentication.v1.0+json" })!.href
          let authData = try Data(contentsOf: URL(string: authDocumentUrl)!)
          let _ = try OPDS2AuthenticationDocument.fromData(authData)
        } catch (let error) {
          errors.append("\(publication.metadata.title): \(error)")
        }
      }
    } catch (let error) {
      XCTAssert(false, error.localizedDescription)
    }
    XCTAssertEqual(errors, [])
  }
  
  func testInitAccountsWithPublication() {
    do {
      let data = try Data(contentsOf: testFeedUrl)
      let feed = try OPDS2LibraryRegistryFeed.fromData(data)
      
      let bpl = Account(libraryCatalog: feed.catalogs.first(where: { $0.metadata.title == "Boston Public Library" })!)
      let gpl = Account(libraryCatalog: feed.catalogs.first(where: { $0.metadata.title == "Glendora Public Library" })!)
      let acl = Account(libraryCatalog: feed.catalogs.first(where: { $0.metadata.title == "Alameda County Library" })!)
      let dpl = Account(libraryCatalog: feed.catalogs.first(where: { $0.metadata.title == "Digital Public Library of America" })!)
      let nypl = Account(libraryCatalog: feed.catalogs.first(where: { $0.metadata.title == "The New York Public Library" })!)
      
      XCTAssertEqual(bpl.name, "Boston Public Library")
      XCTAssertNil(bpl.subtitle)
      XCTAssertEqual(bpl.uuid, "urn:uuid:edef2358-9f6a-4ce6-b64f-9b351ec68ac4")
      XCTAssertEqual(bpl.catalogUrl, "https://bplsimplye.bplibrary.org/NYBKLYN/")
      XCTAssertEqual(bpl.supportEmail, "askus@bplibrary.org")
      XCTAssertEqual(bpl.authenticationDocumentUrl, "https://bplsimplye.bplibrary.org/NYBKLYN/authentication_document")
      XCTAssertNotNil(bpl.logo)
      XCTAssertEqual(bpl.distance, "14 km")
      XCTAssertEqual(bpl.area, "Kings County, NY")
      XCTAssertEqual(bpl.areaType, "local")
      
      XCTAssertEqual(gpl.name, "Glendora Public Library")
      XCTAssertEqual(gpl.subtitle, "Connecting people to the world of ideas, information, and imagination")
      XCTAssertEqual(gpl.uuid, "urn:uuid:a7bddadc-91c7-45a3-a642-dfd137480a22")
      XCTAssertEqual(gpl.catalogUrl, "http://califa108.simplye-ca.org/CAGLEN/")
      XCTAssertEqual(gpl.supportEmail, "library@glendoralibrary.org")
      XCTAssertEqual(gpl.authenticationDocumentUrl, "http://califa108.simplye-ca.org/CAGLEN/authentication_document")
      XCTAssertNotNil(gpl.logo)
      XCTAssertEqual(gpl.distance, nil)
      XCTAssertEqual(gpl.area, nil)
      XCTAssertEqual(gpl.areaType, "state")

      XCTAssertEqual(acl.name, "Alameda County Library")
      XCTAssertEqual(acl.subtitle, "Infinite possibilities")
      XCTAssertEqual(acl.uuid, "urn:uuid:bce4c73c-9d0b-4eac-92e1-1405bcee9367")
      XCTAssertEqual(acl.catalogUrl, "http://acl.simplye-ca.org/CALMDA/")
      XCTAssertEqual(acl.supportEmail, "simplye@aclibrary.org")
      XCTAssertEqual(acl.authenticationDocumentUrl, "http://acl.simplye-ca.org/CALMDA/authentication_document")
      XCTAssertNotNil(acl.logo)
      XCTAssertEqual(acl.distance, nil)
      XCTAssertEqual(acl.area, nil)
      XCTAssertEqual(acl.areaType, "county")

      XCTAssertEqual(dpl.name, "Digital Public Library of America")
      XCTAssertEqual(dpl.subtitle, "Popular books free to download and keep, handpicked by librarians across the US.")
      XCTAssertEqual(dpl.uuid, "urn:uuid:6b849570-070f-43b4-9dcc-7ebb4bca292e")
      XCTAssertEqual(dpl.catalogUrl, "https://openbookshelf.dp.la/OB/groups/3")
      XCTAssertEqual(dpl.supportEmail, "ebooks@dp.la")
      XCTAssertEqual(dpl.authenticationDocumentUrl, "https://openbookshelf.dp.la/OB/authentication_document")
      XCTAssertNotNil(dpl.logo)
      XCTAssertEqual(dpl.distance, nil)
      XCTAssertEqual(dpl.area, nil)
      XCTAssertEqual(dpl.areaType, "universal")

      XCTAssertEqual(nypl.name, "The New York Public Library")
      XCTAssertEqual(nypl.subtitle, nil)
      XCTAssertEqual(nypl.uuid, "urn:uuid:065c0c11-0d0f-42a3-82e4-277b18786949")
      XCTAssertEqual(nypl.catalogUrl, "https://circulation.librarysimplified.org/NYNYPL/")
      XCTAssertEqual(nypl.supportEmail, "gethelp@nypl.org")
      XCTAssertEqual(nypl.authenticationDocumentUrl, "https://circulation.librarysimplified.org/NYNYPL/authentication_document")
      XCTAssertNotNil(nypl.logo)
      XCTAssertEqual(nypl.distance, nil)
      XCTAssertEqual(nypl.area, nil)
      XCTAssertEqual(nypl.areaType, "national")
      
    } catch (let error) {
      XCTAssert(false, error.localizedDescription)
    }
  }
  
  func testAccountSetAuthenticationDocument() {
    do {
      let data = try Data(contentsOf: testFeedUrl)
      let feed = try OPDS2LibraryRegistryFeed.fromData(data)
      
      let bpl = Account(libraryCatalog: feed.catalogs.first(where: { $0.metadata.title == "Boston Public Library" })!)
      let gpl = Account(libraryCatalog: feed.catalogs.first(where: { $0.metadata.title == "Glendora Public Library" })!)
      let acl = Account(libraryCatalog: feed.catalogs.first(where: { $0.metadata.title == "Alameda County Library" })!)
      let dpl = Account(libraryCatalog: feed.catalogs.first(where: { $0.metadata.title == "Digital Public Library of America" })!)
      let nypl = Account(libraryCatalog: feed.catalogs.first(where: { $0.metadata.title == "The New York Public Library" })!)
      
      bpl.authenticationDocument = try OPDS2AuthenticationDocument.fromData(try Data(contentsOf: bplAuthUrl))
      gpl.authenticationDocument = try OPDS2AuthenticationDocument.fromData(try Data(contentsOf: gplAuthUrl))
      acl.authenticationDocument = try OPDS2AuthenticationDocument.fromData(try Data(contentsOf: aclAuthUrl))
      dpl.authenticationDocument = try OPDS2AuthenticationDocument.fromData(try Data(contentsOf: dplAuthUrl))
      nypl.authenticationDocument = try OPDS2AuthenticationDocument.fromData(try Data(contentsOf: nyplAuthUrl))

      XCTAssertEqual(bpl.details?.defaultAuth?.needsAuth, true)
      XCTAssertEqual(bpl.details?.uuid, bpl.uuid)
      XCTAssertEqual(bpl.details?.supportsReservations, true)
      XCTAssertEqual(bpl.details?.userProfileUrl, "https://bplsimplye.bplibrary.org/NYBKLYN/patrons/me/")
      XCTAssertEqual(bpl.details?.supportsSimplyESync, true)
      XCTAssertEqual(bpl.details?.signUpUrl, URL(string: "https://disc.bplibrary.org/ecard/"))
      XCTAssertEqual(bpl.details?.supportsCardCreator, false)
      XCTAssertEqual(bpl.details?.getLicenseURL(.privacyPolicy), URL(string: "https://www.bplibrary.org/use-the-library/policy/privacy-statement"))
      XCTAssertEqual(bpl.details?.getLicenseURL(.eula), nil)
      XCTAssertEqual(bpl.details?.getLicenseURL(.contentLicenses), nil)
      XCTAssertEqual(bpl.details?.getLicenseURL(.acknowledgements), nil)
      XCTAssertEqual(bpl.details?.mainColor, "blue")
      XCTAssertEqual(bpl.details?.defaultAuth?.supportsBarcodeScanner, true)
      XCTAssertEqual(bpl.details?.defaultAuth?.supportsBarcodeDisplay, true)
      XCTAssertEqual(bpl.details?.defaultAuth?.patronIDKeyboard, .standard)
      XCTAssertEqual(bpl.details?.defaultAuth?.pinKeyboard, .numeric)
      XCTAssertEqual(bpl.details?.defaultAuth?.authPasscodeLength, 4)

      XCTAssertEqual(gpl.details?.defaultAuth?.needsAuth, true)
      XCTAssertEqual(gpl.details?.uuid, gpl.uuid)
      XCTAssertEqual(gpl.details?.supportsReservations, true)
      XCTAssertEqual(gpl.details?.userProfileUrl, "http://califa108.simplye-ca.org/CAGLEN/patrons/me/")
      XCTAssertEqual(gpl.details?.supportsSimplyESync, true)
      XCTAssertEqual(gpl.details?.signUpUrl, URL(string:"https://catalog.ci.glendora.ca.us/polaris/patronaccount/selfregister.aspx?ctx=3.1033.0.0.1"))
      XCTAssertEqual(gpl.details?.supportsCardCreator, false)
      XCTAssertEqual(gpl.details?.getLicenseURL(.privacyPolicy), URL(string: "http://califa.org/privacy-policy"))
      XCTAssertEqual(gpl.details?.getLicenseURL(.eula), URL(string: "https://www.librarysimplified.org/EULA/"))
      XCTAssertEqual(gpl.details?.getLicenseURL(.contentLicenses), URL(string: "http://califa.org/third-party-content"))
      XCTAssertEqual(gpl.details?.getLicenseURL(.acknowledgements), nil)
      XCTAssertEqual(gpl.details?.mainColor, "blue")
      XCTAssertEqual(gpl.details?.defaultAuth?.supportsBarcodeScanner, true)
      XCTAssertEqual(gpl.details?.defaultAuth?.supportsBarcodeDisplay, true)
      XCTAssertEqual(gpl.details?.defaultAuth?.patronIDKeyboard, .numeric)
      XCTAssertEqual(gpl.details?.defaultAuth?.pinKeyboard, .numeric)
      XCTAssertEqual(gpl.details?.defaultAuth?.authPasscodeLength, 99)

      XCTAssertEqual(acl.details?.defaultAuth?.needsAuth, true)
      XCTAssertEqual(acl.details?.uuid, acl.uuid)
      XCTAssertEqual(acl.details?.supportsReservations, true)
      XCTAssertEqual(acl.details?.userProfileUrl, "http://acl.simplye-ca.org/CALMDA/patrons/me/")
      XCTAssertEqual(acl.details?.supportsSimplyESync, true)
      XCTAssertEqual(acl.details?.signUpUrl, nil)
      XCTAssertEqual(acl.details?.supportsCardCreator, false)
      XCTAssertEqual(acl.details?.getLicenseURL(.privacyPolicy), URL(string: "http://califa.org/privacy-policy"))
      XCTAssertEqual(acl.details?.getLicenseURL(.eula), URL(string: "https://www.librarysimplified.org/EULA/"))
      XCTAssertEqual(acl.details?.getLicenseURL(.contentLicenses), URL(string: "http://guides.aclibrary.org/TAC"))
      XCTAssertEqual(acl.details?.getLicenseURL(.acknowledgements), nil)
      XCTAssertEqual(acl.details?.mainColor, "lightblue")
      XCTAssertEqual(acl.details?.defaultAuth?.supportsBarcodeScanner, false)
      XCTAssertEqual(acl.details?.defaultAuth?.supportsBarcodeDisplay, false)
      XCTAssertEqual(acl.details?.defaultAuth?.patronIDKeyboard, .numeric)
      XCTAssertEqual(acl.details?.defaultAuth?.pinKeyboard, .standard)
      XCTAssertEqual(acl.details?.defaultAuth?.authPasscodeLength, 99)
      
      XCTAssertEqual(dpl.details?.auths.count, 0)
      XCTAssertNil(dpl.details?.defaultAuth)
      XCTAssertEqual(dpl.details?.uuid, dpl.uuid)
      XCTAssertEqual(dpl.details?.supportsReservations, false)
      XCTAssertEqual(dpl.details?.userProfileUrl, "http://openbookshelf.dp.la/OB/patrons/me/")
      XCTAssertEqual(dpl.details?.supportsSimplyESync, true)
      XCTAssertEqual(dpl.details?.signUpUrl, nil)
      XCTAssertEqual(dpl.details?.supportsCardCreator, false)
      XCTAssertEqual(dpl.details?.getLicenseURL(.privacyPolicy), nil)
      XCTAssertEqual(dpl.details?.getLicenseURL(.eula), nil)
      XCTAssertEqual(dpl.details?.getLicenseURL(.contentLicenses), nil)
      XCTAssertEqual(dpl.details?.getLicenseURL(.acknowledgements), nil)
      XCTAssertEqual(dpl.details?.mainColor, "cyan")

      XCTAssertEqual(nypl.details?.defaultAuth?.needsAuth, true)
      XCTAssertEqual(nypl.details?.uuid, nypl.uuid)
      XCTAssertEqual(nypl.details?.supportsReservations, true)
      XCTAssertEqual(nypl.details?.userProfileUrl, "https://circulation.librarysimplified.org/NYNYPL/patrons/me/")
      XCTAssertEqual(nypl.details?.supportsSimplyESync, true)
      XCTAssertNotNil(nypl.details?.signUpUrl)
      XCTAssertEqual(nypl.details?.signUpUrl,
                     URL(string: "https://patrons.librarysimplified.org/"))
      XCTAssert(nypl.details?.supportsCardCreator ?? false)
      XCTAssertEqual(nypl.details?.getLicenseURL(.privacyPolicy),
                     URL(string: "https://www.nypl.org/help/about-nypl/legal-notices/privacy-policy"))
      XCTAssertEqual(nypl.details?.getLicenseURL(.eula), URL(string: "https://librarysimplified.org/EULA/"))
      XCTAssertEqual(nypl.details?.getLicenseURL(.contentLicenses),
                     URL(string: "https://librarysimplified.org/licenses/"))
      XCTAssertEqual(nypl.details?.mainColor, "red")
      XCTAssertEqual(nypl.details?.defaultAuth?.supportsBarcodeScanner, true)
      XCTAssertEqual(nypl.details?.defaultAuth?.supportsBarcodeDisplay, true)
      XCTAssertEqual(nypl.details?.defaultAuth?.patronIDKeyboard, .standard)
      XCTAssertEqual(nypl.details?.defaultAuth?.pinKeyboard, .standard)
      XCTAssertEqual(nypl.details?.defaultAuth?.authPasscodeLength, 12)
      
    } catch (let error) {
      XCTAssert(false, error.localizedDescription)
    }
  }

}
