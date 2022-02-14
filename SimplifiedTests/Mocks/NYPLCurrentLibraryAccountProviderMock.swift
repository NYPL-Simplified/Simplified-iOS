//
//  NYPLCurrentLibraryAccountProviderMock.swift
//  SimplyETests
//
//  Created by Ernest Fan on 2021-03-11.
//  Copyright © 2021 NYPL. All rights reserved.
//

import Foundation
@testable import SimplyE

class NYPLCurrentLibraryAccountProviderMock: NSObject, NYPLCurrentLibraryAccountProvider {
  var currentAccount: Account?
  
  override init() {
    let feedURL = Bundle(for: NYPLLibraryAccountMock.self)
      .url(forResource: "OPDS2CatalogsFeed", withExtension: "json")!

    let simplyeAuthDocURL = Bundle(for: NYPLLibraryAccountMock.self)
    .url(forResource: "simplye_authentication_document", withExtension: "json")!
    
    let feedData = try! Data(contentsOf: feedURL)
    let feed = try! OPDS2CatalogsFeed.fromData(feedData)

    currentAccount = Account(publication: feed.catalogs.first(where: { $0.metadata.title == "Books for All" })!)
    
    super.init()
    
    currentAccount?.authenticationDocument = try! OPDS2AuthenticationDocument.fromData(try Data(contentsOf: simplyeAuthDocURL))
  }
}
