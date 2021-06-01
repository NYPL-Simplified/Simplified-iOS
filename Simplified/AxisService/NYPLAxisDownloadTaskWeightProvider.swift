//
//  NYPLAxisDownloadTaskWeightProvider.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-06-01.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

protocol NYPLAxisWeightProviding {
  func fixedWeightForTaskWithURL(_ url: URL) -> Double?
}

struct NYPLAxisDownloadTaskWeightProvider: NYPLAxisWeightProviding {
  
  private let axisKeysProvider: NYPLAxisKeysProviding
  
  init(axisKeysProvider: NYPLAxisKeysProviding = NYPLAxisKeysProvider()) {
    self.axisKeysProvider = axisKeysProvider
  }
  
  /// - Note: We're assigning 5 % weight to license, encryption, container, and package. The figure is
  /// purely arbitrary as of now.
  func fixedWeightForTaskWithURL(_ url: URL) -> Double? {
    
    let urlString = url.absoluteString
    
    // Downloading license
    if urlString.contains(axisKeysProvider.licenseBaseURL.absoluteString) {
      return 0.05
    }
    
    // Downloading encryption
    if urlString.contains(axisKeysProvider.encryptionDownloadEndpoint) {
      return 0.05
    }
    
    // Downloading container
    if urlString.contains(axisKeysProvider.containerDownloadEndpoint) {
      return 0.05
    }
    
    // Downloading package
    if url.pathExtension.contains(axisKeysProvider.packageExtension) {
      return 0.05
    }
    
    return nil
  }
  
}
