//
//  NYPLAxisMetadataService.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-05-11.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

protocol NYPLAxisMetadataContentHandling {
  func downloadMetadataTasks() -> [NYPLAxisTask]
}

struct NYPLAxisMetadataService: NYPLAxisMetadataContentHandling {
  let axisItemDownloader: NYPLAxisItemDownloading
  let axisKeysProvider: NYPLAxisKeysProviding
  let baseURL: URL
  let parentDirectory: URL
  
  /// Downloads metadata items (`container.xml` & `encryption.xml`) required for the book.
  func downloadMetadataTasks() -> [NYPLAxisTask] {
    let encryptionDownloadTask = itemDownloadTask(
      endpoint: axisKeysProvider.encryptionDownloadEndpoint)
    let containerDownloadTask = itemDownloadTask(
      endpoint: axisKeysProvider.containerDownloadEndpoint)
    
    return [encryptionDownloadTask, containerDownloadTask]
  }
  
  private func itemDownloadTask(endpoint: String) -> NYPLAxisTask {
    return NYPLAxisTask() { task in
      let itemURL = self.baseURL.appendingPathComponent(endpoint)
      let writeURL = self.parentDirectory.appendingPathComponent(endpoint)
      self.axisItemDownloader.downloadItem(from: itemURL, at: writeURL) {
        task.processResult($0)
      }
    }
  }
  
}
