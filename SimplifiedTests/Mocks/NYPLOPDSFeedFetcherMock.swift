//
//  NYPLOPDSFeedFetcherMock.swift
//  Simplified
//
//  Created by Ernest Fan on 2022-01-04.
//  Copyright © 2022 NYPL. All rights reserved.
//

import Foundation
@testable import SimplyE

enum NYPLOPDSFeedFetcherTestType {
  case retryThreshold
  case invertBookType
  case failRequest
  case none
}

enum NYPLCatalogUngroupedFeedBookType {
  case supported
  case unsupported
  case zeroBooks
  
  func url() -> URL {
    switch self {
    case .supported:
      return Bundle.init(for: NYPLOPDSFeedFetcherMock.self)
        .url(forResource: "NYPLCatalogUngroupedFeedWithSupportedBooks", withExtension: "xml")!
    case .unsupported:
      return Bundle.init(for: NYPLOPDSFeedFetcherMock.self)
        .url(forResource: "NYPLCatalogUngroupedFeedWithUnsupportedBooks", withExtension: "xml")!
    case .zeroBooks:
      return Bundle.init(for: NYPLOPDSFeedFetcherMock.self)
        .url(forResource: "NYPLCatalogUngroupedFeedWithZeroBooks", withExtension: "xml")!
    }
  }
}

class NYPLOPDSFeedFetcherMock: NYPLOPDSFeedFetcher {
  // Type of test on going
  static var testType: NYPLOPDSFeedFetcherTestType = .none
  
  // A decremental counter which performs the test when it reaches 0
  static var numberOfFetchAllowed = 5
  
  // Overriding this function in order to mimick the response from server
  override class func fetchOPDSFeed(url: URL?,
                                    networkExecutor: NYPLRequestExecutingObjC,
                                    shouldResetCache: Bool,
                                    completion: @escaping (NYPLOPDSFeed?, [String : Any]?) -> Void) {
    var requestURL = url
    switch testType {
    case .invertBookType:
      // Supported book feed is returned after receiving a couple of unsupported book feeds
      if numberOfFetchAllowed > 0 {
        requestURL = NYPLCatalogUngroupedFeedBookType.unsupported.url()
      } else {
        requestURL = NYPLCatalogUngroupedFeedBookType.supported.url()
      }
    case .failRequest:
      // Any failure (eg. network error, parsing error etc.)
      if numberOfFetchAllowed <= 0 {
        completion(nil, nil)
        return
      } else {
        requestURL = NYPLCatalogUngroupedFeedBookType.unsupported.url()
      }
    case .retryThreshold:
      // Returned feeds containing only unsupported books
      requestURL = NYPLCatalogUngroupedFeedBookType.unsupported.url()
    case .none:
      break
    }
    
    guard let requestURL = requestURL else {
      completion(nil, nil)
      return
    }
    
    numberOfFetchAllowed -= 1
    
    do {
      let data = try Data(contentsOf: requestURL)
      let xml = NYPLXML.init(data: data)
      
      let feed = NYPLOPDSFeed.init(xml: xml)
      completion(feed, nil)
    } catch {
      completion(nil, nil)
    }
  }
}
