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
  static let axisError = NSError(domain: "Axis Service failed", code: 500, userInfo: nil)
  
  private weak var delegate: NYPLBookDownloadBroadcasting?
  private let isbn: String
  private let bookVaultId: String
  private let dedicatedDownloadURL: URL
  private let fileURL: URL
  
  @objc
  init?(withDelegate delegate: NYPLBookDownloadBroadcasting, fileURL: URL) {
    
    do {
      let data = try Data(contentsOf: fileURL)
      let jsonObject = try JSONSerialization
        .jsonObject(with: data, options: .fragmentsAllowed)
      
      guard
        let json = jsonObject as? [String: Any],
        let isbn = json["isbn"] as? String,
        let bookVaultId = json["book_vault_uuid"] as? String
        else {
          return nil
      }
      
      self.isbn = isbn
      self.fileURL = fileURL
      self.delegate = delegate
      self.bookVaultId = bookVaultId
      self.dedicatedDownloadURL = fileURL.deletingLastPathComponent().appendingPathComponent(isbn)
      
    } catch {
      print("error initiating AxisService: \(error)")
      return nil
    }
  }
  
  /// Fulfill AxisNow license
  /// - Parameters:
  ///   - book: `NYPLBook` Book
  ///   - downloadTask: downloadTask download task
  @objc func fulfillAxisLicense(forBook book: NYPLBook,
                                downloadTask: URLSessionDownloadTask) {
    
    
    
    
    
  }
  
  
  
  
}



#endif
