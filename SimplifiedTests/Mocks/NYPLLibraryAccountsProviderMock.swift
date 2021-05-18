//
//  NYPLLibraryAccountsProviderMock.swift
//  Simplified
//
//  Created by Ettore Pasquini on 10/14/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation
@testable import SimplyE

class NYPLLibraryAccountMock: NSObject, NYPLLibraryAccountsProvider {
  let feedURL: URL
  let nyplAuthDocURL: URL
  let feed: OPDS2LibraryRegistryFeed
  let nyplAccount: Account

  override init() {
    feedURL = Bundle(for: NYPLLibraryAccountMock.self)
      .url(forResource: "OPDS2LibraryRegistryFeed", withExtension: "json")!

    nyplAuthDocURL = Bundle(for: NYPLLibraryAccountMock.self)
      .url(forResource: "nypl_authentication_document", withExtension: "json")!

    let feedData = try! Data(contentsOf: feedURL)
    feed = try! OPDS2LibraryRegistryFeed.fromData(feedData)

    nyplAccount = Account(libraryCatalog: feed.catalogs.first(where: { $0.metadata.title == "The New York Public Library" })!)

    super.init()

    nyplAccount.authenticationDocument = try! OPDS2AuthenticationDocument.fromData(try Data(contentsOf: nyplAuthDocURL))
  }

  var barcodeAuthentication: AccountDetails.Authentication {
    return nyplAccount.details!.auths.first { $0.authType == .basic }!
  }

  var oauthAuthentication: AccountDetails.Authentication {
    return nyplAccount.details!.auths.first { $0.authType == .oauthIntermediary }!
  }

  var cleverAuthentication: AccountDetails.Authentication {
    return oauthAuthentication
  }

  var samlAuthentication: AccountDetails.Authentication {
    return nyplAccount.details!.auths.first { $0.authType == .saml }!
  }

  var NYPLAccountUUID: String {
    return nyplAccount.uuid
  }

  var currentAccountId: String? {
    return nyplAccount.uuid
  }

  var currentAccount: Account? {
    return nyplAccount
  }

  func createOPDS2LibraryCatalog() -> OPDS2LibraryCatalog {
    let link = OPDS2Link(href: "href\(arc4random())",
                         type: "type\(arc4random())",
                         rel: "rel\(arc4random())",
                         templated: false,
                         displayNames: nil,
                         descriptions: nil)
    let subject = OPDS2LibraryCatalog.Metadata.Subject(name: "subjectName",
                                                       code: "subjectCode",
                                                       scheme: "subjectScheme")
    let metadata = OPDS2LibraryCatalog.Metadata(title: "metadataTitle",
                                                description: "OPDS2 metadata",
                                                identifier: "metadataIdentifier",
                                                modified: Date(),
                                                distance: "metadataDistance",
                                                area: "metadataArea",
                                                subject: [subject])
    let catalog = OPDS2LibraryCatalog(links: [link],
                                      metadata: metadata,
                                      images: nil)
    return catalog
  }

  /// Pass in the empty string to get a nil account.
  func account(_ uuid: String) -> Account? {
    if uuid.isEmpty {
      return nil
    } else if uuid == NYPLAccountUUID {
      return nyplAccount
    } else {
      let catalog = createOPDS2LibraryCatalog()
      return Account(libraryCatalog: catalog)
    }
  }
}
