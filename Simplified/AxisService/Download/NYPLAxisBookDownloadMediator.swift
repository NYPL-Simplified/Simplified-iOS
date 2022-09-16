//
//  NYPLAxisBookDownloadMediator.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-06-23.
//  Copyright © 2021 NYPL. All rights reserved.
//

import Foundation
import NYPLAxis

class NYPLAxisBookDownloadMediator: NYPLAxisBookDownloadListening {
  
  private weak var delegate: NYPLBookDownloadBroadcasting?
  private let book: NYPLBook
  private let downloadTask: URLSessionDownloadTask
  
  init(with delegate: NYPLBookDownloadBroadcasting?, book: NYPLBook, downloadTask: URLSessionDownloadTask) {
    self.delegate = delegate
    self.book = book
    self.downloadTask = downloadTask
  }
  
  func downloadProgressDidUpdate(to progress: Double) {
    delegate?.downloadProgressDidUpdate(to: progress, forBook: book)
  }
  
  func downloadDidFail(with error: Error) {
    delegate?.failDownloadWithAlert(forBook: book, error: error)
  }
  
  func didFinishDownloadingBook(to sourceLocation: URL) {
    _ = delegate?
      .replaceBook(
        book, withFileAtURL: sourceLocation, forDownloadTask: downloadTask)
  }
  
}
