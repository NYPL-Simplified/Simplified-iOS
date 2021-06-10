//
//  NYPLAxisMetadataService.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-05-11.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

protocol NYPLAxisMetadataContentHandling {
  func downloadContent()
}

struct NYPLAxisMetadataService: NYPLAxisMetadataContentHandling {
  let axisItemDownloader: NYPLAxisItemDownloading
  let axisKeysProvider: NYPLAxisKeysProviding
  let baseURL: URL
  let parentDirectory: URL
  
  /// Downloads metadata items (`container.xml` & `encryption.xml`) required for the book.
  func downloadContent() {
    downloadItem(endpoint: axisKeysProvider.encryptionDownloadEndpoint)
    downloadItem(endpoint: axisKeysProvider.containerDownloadEndpoint)
  }
  
  private func downloadItem(endpoint: String) {
    // No need to log error here since itemDownloader already logs one
    guard axisItemDownloader.shouldContinue else {
      return
    }
    
    let itemURL = baseURL.appendingPathComponent(endpoint)
    let writeURL = parentDirectory.appendingPathComponent(endpoint)
    axisItemDownloader.downloadItem(from: itemURL, at: writeURL)
  }
  
}
