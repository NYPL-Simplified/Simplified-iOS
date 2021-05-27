//
//  NYPLLibraryFinderBusinessLogic.swift
//  Simplified
//
//  Created by Ernest Fan on 2021-04-21.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
import CoreLocation

protocol NYPLLibraryFinderDataProviding {
  var userAccounts: [Account] { get }
  var newLibraryAccounts: [Account] { get }
  
  // Might need to add pagination to the request
  func requestLibraryList(searchKeyword: String?, completion: @escaping (Bool) -> ())
}

/// Keys for query items when requesting library registry feed for Finder
/// - Parameter location: latitude and longitude of user's location
/// - Parameter stage: request production or beta library registry feed
/// - Parameter search: search keyword entered by user
/// eg: http://librarysimplified.org/terms/rel/search?location=41,-87&query=springfield&stage=all
/// ref: https://github.com/NYPL-Simplified/Simplified/wiki/LibraryRegistryPublicAPI#template-variables-1

enum LibraryFinderQueryItemKey: String {
  case location
  case stage
  case search = "query"
}

enum LibraryFinderQueryStage: String {
  case production
  case beta = "all"
}

class NYPLLibraryFinderBusinessLogic: NSObject, NYPLLibraryFinderDataProviding {
  private let searchUrlString = "http://librarysimplified.org/terms/rel/search"
  private let nearbyUrlString = "http://librarysimplified.org/terms/rel/nearby"
  
  let userAccounts: [Account]
  var newLibraryAccounts: [Account]
  let libraryRegistry: NYPLLibraryRegistryFeedRequestHandling
  
  var userLocation: CLLocationCoordinate2D? = nil
  
  init(userAccounts: [Account] = [Account](), libraryRegistry: NYPLLibraryRegistryFeedRequestHandling) {
    self.userAccounts = userAccounts
    self.newLibraryAccounts = [Account]()
    self.libraryRegistry = libraryRegistry
  }
  
  func requestLibraryList(searchKeyword: String?, completion: @escaping (Bool) -> ()) {
    guard let targetUrl = getRequestUrl(searchKeyword: searchKeyword) else {
      completion(false)
      return
    }
    
    Log.debug(#function, targetUrl.absoluteString)
    
    libraryRegistry.loadCatalogs(url: targetUrl) { [weak self] success in
      guard let self = self else {
        return
      }
      
      if success {
        let userAccountUUIDs: [String] = self.userAccounts.compactMap { $0.uuid }
        let filteredAccounts = self.libraryRegistry.accounts(nil).filter {
          !userAccountUUIDs.contains($0.uuid)
        }
        self.newLibraryAccounts = filteredAccounts
      }
      completion(success)
    }
  }
  
  private func getRequestUrl(searchKeyword: String?) -> URL? {
    var queryItems = [URLQueryItem]()
    var targetUrlString = userLocation != nil ? nearbyUrlString : searchUrlString
    
    if let searchKeyword = searchKeyword,
       searchKeyword.count > 0
    {
      targetUrlString = searchUrlString
      queryItems.append(
        URLQueryItem(
          name: LibraryFinderQueryItemKey.search.rawValue,
          value: searchKeyword
        )
      )
    }
    
    if let location = userLocation {
      let locationString = "\(location.latitude),\(location.longitude)"
      queryItems.append(
        URLQueryItem(
          name: LibraryFinderQueryItemKey.location.rawValue,
          value: locationString
        )
      )
    }
    
    queryItems.append(
      URLQueryItem(
        name: LibraryFinderQueryItemKey.stage.rawValue,
        value: NYPLSettings.shared.useBetaLibraries ? LibraryFinderQueryStage.beta.rawValue : LibraryFinderQueryStage.production.rawValue
      )
    )
    
    var urlComponents = URLComponents(string: targetUrlString)
    urlComponents?.queryItems = queryItems
    
    return urlComponents?.url
  }
}
