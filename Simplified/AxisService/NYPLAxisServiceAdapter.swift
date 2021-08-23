//
//  NYPLAxisServiceAdapter.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-06-23.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
import NYPLAxis

@objc protocol NYPLBookDownloadBroadcasting {
  func downloadProgressDidUpdate(to progress: Double, forBook book: NYPLBook)
  func failDownloadWithAlert(forBook book: NYPLBook)
  func replaceBook(_ book: NYPLBook,
                   withFileAtURL sourceLocation: URL,
                   forDownloadTask downloadtask: URLSessionDownloadTask) -> Bool
}

@objc
class NYPLAxisBookDownloadAdapter: NSObject {
  
  private let axisService: NYPLAxisService
  private let mediator: NYPLAxisBookDownloadMediator
  
  @objc
  init?(downloadTask: URLSessionDownloadTask,
       book: NYPLBook,
       downloadBroadcaster: NYPLBookDownloadBroadcasting,
       fileURL: URL) {
    
    let mediator = NYPLAxisBookDownloadMediator(
      with: downloadBroadcaster, book: book, downloadTask: downloadTask)
    let errorLogsAdapter = NYPLAxisErrorLogsAdapter()
    
    guard let service = NYPLAxisService(
            delegate: mediator, fileURL: fileURL,
            forBookWithIdentifier: book.identifier,
            downloader: NYPLAxisContentDownloader(),
            sha: book.identifier.sha256(), errorLogger: errorLogsAdapter,
            axisXMLCreator: NYPLAxisXMLCreator())
    else {
      return nil
    }
    
    self.mediator = mediator
    self.axisService = service
  }

  
  
  /// Triggers all the tasks required for downloading an Axis book (LicenseService tasks,
  /// MetadataService tasks, & PackageService tasks)
  @objc func downloadBook() {
    axisService.fulfillAxisLicense()
  }
  
  @objc
  func downloadCancelledByUser() {
    axisService.downloadCancelledByUser()
  }
  
}
