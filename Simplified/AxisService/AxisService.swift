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
    
    let dispatchGroup = DispatchGroup()
//    downloadLicense(group: dispatchGroup, forBook: book)
    downloadEncryption(group: dispatchGroup, forBook: book)
    downloadContainer(group: dispatchGroup, forBook: book)
    downloadPackage(group: dispatchGroup, forBook: book)
    downloadAssetsFromPackage(group: dispatchGroup, forBook: book)
    
    dispatchGroup.notify(queue: DispatchQueue.main) {
      print("All items downloaded!")
    }
  }
  
  private func downloadLicense(group: DispatchGroup, forBook book: NYPLBook) {
    group.enter()
    let writeURL = dedicatedWriteURL.appendingPathComponent("license.json")
    guard let licenseURL = AxisLicenseURLGenerator(
      isbn: self.isbn,
      bookVaultId: self.bookVaultId
    ).licenseURL else {
      return
    }
    
    AxisContentDownloader().downloadContent(from: licenseURL) { (result) in
      switch result {
      case .success(let data):
        do {
          try AxisAssetWriter().writeAsset(data, atURL: writeURL)
          group.leave()
        } catch {
          print(error)
          group.leave()
          self.delegate?.failDownloadWithAlert(forBook: book)
        }
      case .failure(let error):
        print(error)
        group.leave()
        self.delegate?.failDownloadWithAlert(forBook: book)
      }
      
    }
  }
  
  private func downloadEncryption(group: DispatchGroup, forBook book: NYPLBook) {
    group.enter()
    let baseURL = URL(string: "https://node.axisnow.com/content/stream/\(self.isbn)/")!
    let containerURL = baseURL.appendingPathComponent("META-INF/encryption.xml")
    let writeURL = self.dedicatedWriteURL.appendingPathComponent("encryption.xml")
    AxisContentDownloader().downloadContent(from: containerURL) { (result) in
      switch result {
      case .success(let data):
        do {
          try AxisAssetWriter().writeAsset(data, atURL: writeURL)
          group.leave()
        } catch {
          print(error)
          group.leave()
          self.delegate?.failDownloadWithAlert(forBook: book)
        }
      case .failure(let error):
        print(error)
        group.leave()
        self.delegate?.failDownloadWithAlert(forBook: book)
      }
    }
  }
  
  private func downloadContainer(group: DispatchGroup, forBook book: NYPLBook) {
    group.enter()
    let containerURL = baseURL.appendingPathComponent("META-INF/container.xml")
    let writeURL = self.dedicatedWriteURL.appendingPathComponent("container.xml")
    AxisContentDownloader().downloadContent(from: containerURL) { (result) in
      switch result {
      case .success(let data):
        do {
          try AxisAssetWriter().writeAsset(data, atURL: writeURL)
          group.leave()
        } catch {
          print(error)
          group.leave()
          self.delegate?.failDownloadWithAlert(forBook: book)
        }
      case .failure(let error):
        print(error)
        group.leave()
        self.delegate?.failDownloadWithAlert(forBook: book)
      }
    }
  }
  
  func downloadPackage(group: DispatchGroup, forBook book: NYPLBook) {
    group.enter()
    guard let endpoint = getContainerEndpoint() else {
      group.leave()
      return
    }

    let packageURL = baseURL.appendingPathComponent(endpoint)
    AxisContentDownloader().downloadContent(from: packageURL) { (result) in
      switch result {
      case .success(let data):
        do {
          try AxisAssetWriter().writeAsset(
            data,
            atURL: self.dedicatedWriteURL.appendingPathComponent(endpoint)
          )
          group.leave()
        } catch {
          print(error)
          group.leave()
          self.delegate?.failDownloadWithAlert(forBook: book)
        }
      case .failure(let error):
        print(error)
        group.leave()
        self.delegate?.failDownloadWithAlert(forBook: book)
      }
    }
  }
  
  private func getContainerEndpoint() -> String? {
    let containerURL = dedicatedWriteURL.appendingPathComponent("container.xml")
    guard
      let data = try? Data(contentsOf: containerURL),
      let xml = NYPLXML(data: data)
      else {
        return nil
    }
    return AxisXML(xml: xml).findRecursivelyInAttributes("full-path").first
  }
  
  private func downloadAssetsFromPackage(group: DispatchGroup, forBook book: NYPLBook) {
    guard let containerEndpoint = getContainerEndpoint() else {
      return
    }
    
    let packageURL = self.dedicatedWriteURL.appendingPathComponent(containerEndpoint)
    guard
      let data = try? Data(contentsOf: packageURL),
      let xml = NYPLXML(data: data)
    else {
      return
    }
    
    let axisXML = AxisXML(xml: xml)
    let hrefs = axisXML.findRecursivelyInAttributes("href").map { return "OEBPS/\($0)" }
    
    for href in hrefs {
      let linkURL = baseURL.appendingPathComponent(href)
      group.enter()
      AxisContentDownloader().downloadContent(from: linkURL) { (result) in
        switch result {
        case .success(let data):
          print("")
          let writeURL = self.dedicatedWriteURL.appendingPathComponent(href)
          do {
            try AxisAssetWriter().writeAsset(data, atURL: writeURL)
            group.leave()
          } catch {
            print(error)
            group.leave()
            self.delegate?.failDownloadWithAlert(forBook: book)
          }
        case .failure(let error):
          print(error)
          group.leave()
          self.delegate?.failDownloadWithAlert(forBook: book)
        }
      }
    }
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
    
    
    
//  }
  
  
}



#endif
