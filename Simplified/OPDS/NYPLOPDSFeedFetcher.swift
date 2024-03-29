//
//  NYPLOPDSFeedFetcher.swift
//  Simplified
//
//  Created by Ernest Fan on 2022-01-09.
//  Copyright © 2022 NYPL. All rights reserved.
//

import Foundation

@objcMembers class NYPLOPDSFeedFetcher: NSObject {
  // The the maximum attempts of books fetching allowed until we receive supported books.
  private static let fetchSupportedBooksRetryThreshold = 15
  
  ///   Fetch catalog feed for given URL.
  ///   If the returned feed does not contain supported books, it will call itself recursively
  ///   until supported books are received or retry threshold reached.
  ///
  ///   - Parameter url: URL for fetching the catalog feed
  ///   - Parameter retryCount: Current number of attempts to fetch supported books
  ///   - Parameter completion: Always invoked at the end no matter what,
  ///   providing an ungrouped feed object in case of success and nil otherwise.
  class func fetchCatalogUngroupedFeed(url: URL?,
                                       networkExecutor: NYPLHTTPRequestExecutingBasic,
                                       retryCount: Int = 0,
                                       completion: @escaping (_ feed: NYPLCatalogUngroupedFeed?) -> Void) {
    guard let url = url else {
      Log.error(#function, "Unable to fetch Catalog feed with empty URL.")
      completion(nil)
      return
    }
    
    if (retryCount >= fetchSupportedBooksRetryThreshold) {
      Log.warn(#function, "Retry threshold reached while fetching Catalog feed.")
      completion(nil)
      return
    }
    
    fetchOPDSFeed(url: url,
                  networkExecutor: networkExecutor,
                  shouldResetCache: false) { feed, error in
      guard let feed = feed,
            feed.type == NYPLOPDSFeedType.acquisitionUngrouped else {
        completion(nil)
        return
      }
    
      let catalogFeed = NYPLCatalogUngroupedFeed.init(opdsFeed: feed)
      if let catalogFeed = catalogFeed,
         catalogFeed.books.count == 0,
         let nextURL = catalogFeed.nextURL {
        // Returned feed contains zero supported books, but more feed is available
        fetchCatalogUngroupedFeed(url: nextURL,
                                  networkExecutor: networkExecutor,
                                  retryCount: retryCount + 1,
                                  completion: completion)
      } else {
        // Feed contains supported books or no books at all
        completion(catalogFeed)
      }
    }
  }
  
  ///   Fetch OPDS feed with a GET request for the given URL.
  ///
  ///   - Parameter url: The URL to contact
  ///   - Parameter shouldResetCache: Pass YES to wipe the whole cache.
  ///   - Parameter completion: Always invoked at the end no matter what,
  ///   providing an OPDS feed object in case of success and an dictionary
  ///   containing error information otherwise.
  ///
  ///   - Note: This function logs events for all error situations.
  ///   - Important: If calling from objc, make sure to nil-check `url`!
  class func fetchOPDSFeed(url: URL,
                           networkExecutor: NYPLHTTPRequestExecutingBasic,
                           shouldResetCache: Bool,
                           completion: @escaping (_ feed: NYPLOPDSFeed?, _ error: [String: Any]?) -> Void) {
    let cachePolicy: NSURLRequest.CachePolicy = shouldResetCache ? .reloadIgnoringCacheData : .useProtocolCachePolicy
    
    _ = networkExecutor.GET(url,
                            cachePolicy: cachePolicy) { result, response, error in
      
      if let error = error as NSError? {
        // Note: NYPLNetworkExecutor already logged this error
        DispatchQueue.global(qos: .default).async {
          completion(nil, error.problemDocument?.dictionaryValue)
        }
        return
      }
      
      guard let feedXML = NYPLXML.init(data: result) else {
        Log.info(#function, "Failed to parse data as XML.")
        NYPLErrorLogger.logError(withCode: .feedParseFail,
                                 summary: "NYPLOPDSFeed: Failed to parse data as XML",
                                 metadata: [
                                  "requestURL": url.absoluteString as Any,
                                  "response":response != nil ? response as Any : "N/A"
                                 ])
        var errorDict: [String: Any]? = nil
        if let data = result,
           let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
          errorDict = jsonObject
        }
        DispatchQueue.global(qos: .default).async {
          completion(nil, errorDict)
        }
        return
      }
      
      guard let feed = NYPLOPDSFeed.init(xml: feedXML) else {
        Log.info(#function, "Could not interpret XML as OPDS..")
        NYPLErrorLogger.logError(withCode: .feedParseFail,
                                 summary: "NYPLOPDSFeed: Failed to parse XML as OPDS",
                                 metadata: [
                                  "requestURL": url.absoluteString as Any,
                                  "response":response != nil ? response as Any : "N/A"
                                 ])
        DispatchQueue.global(qos: .default).async {
          completion(nil, nil)
        }
        return
      }
      
      DispatchQueue.global(qos: .default).async {
        completion(feed, nil)
      }
    }
  }
}
