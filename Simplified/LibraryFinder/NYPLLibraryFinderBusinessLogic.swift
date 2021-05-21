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
  func requestLibraryList(searchKeyword: String?, completion: @escaping (Error?) -> ())
}

enum LibraryFinderQueryItemKey: String {
  case location
  case stage
  case query
}

class NYPLLibraryFinderBusinessLogic: NSObject, NYPLLibraryFinderDataProviding {
  private let searchUrlString = "http://librarysimplified.org/terms/rel/search"
  private let nearbyUrlString = "http://librarysimplified.org/terms/rel/nearby"
  
  // TODO: Use `let` instead of `var` if userAccounts is not intended to change
  var userAccounts: [Account]
  var newLibraryAccounts: [Account]
  
  var userLocation: CLLocationCoordinate2D? = nil
  
  init(userAccounts: [Account] = [Account](), newLibraryAccounts: [Account] = [Account]()) {
    // TODO: iOS-35 Fetch library list from new API endpoints
    self.userAccounts = userAccounts
    self.newLibraryAccounts = newLibraryAccounts
  }
  
  func requestLibraryList(searchKeyword: String?, completion: @escaping (Error?) -> ()) {
    var queryItems = [URLQueryItem]()
    var targetUrlString = userLocation != nil ? nearbyUrlString : searchUrlString
    
    if let searchKeyword = searchKeyword,
       searchKeyword.count > 0
    {
      targetUrlString = searchUrlString
      queryItems.append(
        URLQueryItem(
          name: LibraryFinderQueryItemKey.query.rawValue,
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
        value: NYPLSettings.shared.useBetaLibraries ? "all" : "production"
      )
    )
    
    var urlComponents = URLComponents(string: targetUrlString)
    urlComponents?.queryItems = queryItems
    
    guard let targetUrl = urlComponents?.url else {
      // Handle completion with error
      return
    }
    
    Log.debug(#function, targetUrl.absoluteString)
    
    // For testing
    Log.debug(#file, "API Request - request library list with keyword - \(searchKeyword)")
    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
      completion(nil)
    }
  }
}
