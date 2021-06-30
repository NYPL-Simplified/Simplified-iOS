//
//  NYPLAxisContentDownloader.swift
//  Simplified
//
//  Created by Raman Singh on 2021-04-22.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
import NYPLAxis

class NYPLAxisContentDownloader: NYPLAxisContentDownloading {
  
  let networkExecutor: NYPLAxisNetworkExecuting
  
  init(networkExecuting: NYPLAxisNetworkExecuting = NYPLAxisNetworkExecutor()) {
    self.networkExecutor = networkExecuting
  }
  
  func downloadItem(from url: URL,
                    _ completion: @escaping (Result<Data, Error>) -> Void) {
    let request = URLRequest(url: url,
                             cachePolicy: .reloadIgnoringLocalCacheData,
                             timeoutInterval: networkExecutor.requestTimeout)
    
    _ = networkExecutor.GET(request, completion: completion)
  }
  
}
