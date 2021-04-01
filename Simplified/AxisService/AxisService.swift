//
//  AxisService.swift
//  Simplified
//
//  Created by Raman Singh on 2021-04-01.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

#if FEATURE_DRM_CONNECTOR && OPENEBOOKS

@objc
protocol NYPLBookDownloadBroadcasting {
  func failDownloadWithAlert(forBook book: NYPLBook)
  func replaceBook(_ book: NYPLBook,
                   withFileAtURL sourceLocation: URL,
                   forDownloadTask downloadtask: URLSessionDownloadTask) -> Bool
}

@objc
class AxisService: NSObject {
  private weak var delegate: NYPLBookDownloadBroadcasting?
  
  @objc
  init(withDelegate delegate: NYPLBookDownloadBroadcasting) {
    self.delegate = delegate
  }
  
  /// Fulfill AxisNow license
  /// - Parameters:
  ///   - fileURL: Downloaded LCP license URL
  ///   - book: `NYPLBook` Book
  ///   - downloadTask: downloadTask download task
  @objc func fulfillAxisLicense(withFileURL fileURL: URL,
                                forBook book: NYPLBook,
                                downloadTask: URLSessionDownloadTask) {
    print("")
  }
  
}

#endif
