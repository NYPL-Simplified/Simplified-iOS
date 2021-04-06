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
  private let dedicatedWriteURL: URL
  private let fileURL: URL
  private let baseURL: URL
  
  @objc
  init?(withDelegate delegate: NYPLBookDownloadBroadcasting, fileURL: URL) {
    
    do {
      let data = try Data(contentsOf: fileURL)
      let jsonObject = try JSONSerialization
        .jsonObject(with: data, options: .fragmentsAllowed)
      
      guard
        let json = jsonObject as? [String: Any],
        let isbn = json["isbn"] as? String,
        let bookVaultId = json["book_vault_uuid"] as? String,
        let baseURL = URL(string: "https://node.axisnow.com/content/stream/\(isbn)/")
        else {
          return nil
      }
      
      self.isbn = isbn
      self.fileURL = fileURL
      self.delegate = delegate
      self.bookVaultId = bookVaultId
      self.dedicatedWriteURL = fileURL.deletingLastPathComponent().appendingPathComponent(isbn)
      self.baseURL = baseURL
      
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
    
    let downloadURL = fileURL.deletingLastPathComponent().appendingPathComponent(isbn)
    
//    let contentDownloader = AxisBookContentDownloader(isbn: isbn,
//                                                      bookVaultId: bookVaultId,
//                                                      dedicatedWriteURL: downloadURL)
//    
//    contentDownloader.startDownloadingContent { (result) in
//      switch result {
//      case .success:
//        self.downloadOPFFromContainerURL(forBook: book)
//      case .failure(let error):
//        print(error)
//      }
//    }
    
//    self.downloadOPFFromContainerURL(forBook: book)
  }
  
  
//  private func downloadOPFFromContainerURL(forBook book: NYPLBook) {
//    guard let endpoint = getPackageEndpointFromContainer() else {
//      return
//    }
//
//    let packageURL = baseURL.appendingPathComponent(endpoint)
//
//    AxisContentDownloader().downloadContent(from: packageURL) { (result) in
//      switch result {
//      case .success(let data):
//        do {
//          try AxisAssetWriter().writeAsset(
//            data,
//            atURL: self.dedicatedWriteURL.appendingPathComponent(endpoint))
//        } catch {
//          self.delegate?.failDownloadWithAlert(forBook: book)
//        }
//      case .failure(let error):
//        print(error)
//      }
//    }
//  }
//
//  private func getPackageEndpointFromContainer() -> String? {
//    let containerURL = dedicatedWriteURL.appendingPathComponent("container.xml")
//    guard
//      let data = try? Data(contentsOf: containerURL),
//      let xml = NYPLXML(data: data)
//      else {
//        return nil
//    }
//
//    let axisXML = AxisXML(xml: xml)
//    return axisXML.findRecursivelyInAttributes("full-path").first
//  }
//
//  private func downloadContentFromPackage(forBook book: NYPLBook) {
//
//    guard
//      let packageEndpoint = getPackageEndpointFromContainer(),
//      let data = try? Data(contentsOf: baseURL.appendingPathComponent(packageEndpoint)),
//      let xml = NYPLXML(data: data)
//      else {
//      return
//    }
//
//    let axisXML = AxisXML(xml: xml)
//    let hrefs = axisXML.findRecursivelyInAttributes("href")
    
    
    
  }
  
  
}



#endif
