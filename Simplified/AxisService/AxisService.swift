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
    
    let dispatchGroup = DispatchGroup()
    downloadLicense(group: dispatchGroup, forBook: book)
    dispatchGroup.wait()
    downloadEncryption(group: dispatchGroup, forBook: book)
    dispatchGroup.wait()
    downloadContainer(group: dispatchGroup, forBook: book)
    dispatchGroup.wait()
    downloadPackage(group: dispatchGroup, forBook: book)
    dispatchGroup.wait()
    downloadAssetsFromPackage(group: dispatchGroup, forBook: book)
    
    dispatchGroup.notify(queue: DispatchQueue.main) {
      print("Book content downloaded!")
      //      _ = self.delegate?.replaceBook(
      //        book,
      //        withFileAtURL: self.dedicatedWriteURL,
      //        forDownloadTask: downloadTask)
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
    
    downloadItem(from: licenseURL, at: writeURL, forBook: book, group: group)
  }
  
  private func downloadEncryption(group: DispatchGroup, forBook book: NYPLBook) {
    group.enter()
    let encryptionURL = baseURL.appendingPathComponent("META-INF/encryption.xml")
    let writeURL = self.dedicatedWriteURL.appendingPathComponent("encryption.xml")
    downloadItem(from: encryptionURL, at: writeURL, forBook: book, group: group)
  }
  
  private func downloadContainer(group: DispatchGroup, forBook book: NYPLBook) {
    group.enter()
    let containerURL = baseURL.appendingPathComponent("META-INF/container.xml")
    let writeURL = self.dedicatedWriteURL.appendingPathComponent("container.xml")
    downloadItem(from: containerURL, at: writeURL, forBook: book, group: group)
  }
  
  func downloadPackage(group: DispatchGroup, forBook book: NYPLBook) {
    group.enter()
    guard let endpoint = getContainerEndpoint() else {
      group.leave()
      return
    }
    
    let packageURL = baseURL.appendingPathComponent(endpoint)
    let writeURL = self.dedicatedWriteURL.appendingPathComponent(endpoint)
    downloadItem(from: packageURL, at: writeURL, forBook: book, group: group)
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
      let writeURL = self.dedicatedWriteURL.appendingPathComponent(href)
      group.enter()
      downloadItem(from: linkURL, at: writeURL, forBook: book, group: group)
    }
  }
  
  private func downloadItem(from url: URL,
                            at writeURL: URL,
                            forBook book: NYPLBook,
                            group: DispatchGroup) {
    
    AxisContentDownloader().downloadContent(from: url) { (result) in
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
  
}

#endif
