//
//  AxisBookContentDownloader.swift
//  Simplified
//
//  Created by Raman Singh on 2021-04-01.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

class AxisBookContentDownloader {
  let isbn: String
  let bookVaultId: String
  let dedicatedWriteURL: URL
  private var itemsDownloadedCount: Int
  private var handler: ((Result<Bool, Error>) -> Void)?
  private let totalCountRequired = 2 // change this to 3
  
  init(isbn: String, bookVaultId: String, dedicatedWriteURL: URL) {
    self.isbn = isbn
    self.bookVaultId = bookVaultId
    self.dedicatedWriteURL = dedicatedWriteURL
    self.itemsDownloadedCount = 0
  }
  
  func startDownloadingContent(completion: @escaping (Result<Bool, Error>) -> Void) {
    
    self.handler = completion
    
    let downloadError = NSError(domain: "Failed downloading license",
                                code: 500,
                                userInfo: nil)
    
    let _licenseURL = AxisLicenseURLGenerator(
      isbn: isbn,
      bookVaultId: bookVaultId
    ).licenseURL
    
    guard let licenseURL = _licenseURL else {
      completion(.failure(downloadError))
      return
    }
    
    self.downloadItemFromURL(licenseURL, title: "license.json")
    
    let baseURL = URL(string: "https://node.axisnow.com/content/stream/\(self.isbn)/")!
    let containerURL = baseURL.appendingPathComponent("META-INF/container.xml")
    let encryptionURL = baseURL.appendingPathComponent("META-INF/encryption.xml")
    
    self.downloadItemFromURL(containerURL, title: "container.xml")
    self.downloadItemFromURL(encryptionURL, title: "encryption.xml")
  }
  
  private func downloadItemFromURL(_ url: URL, title: String) {
    let downloader = AxisContentDownloader()
    downloader.downloadContent(from: url) { (result) in
      switch result {
      case .success(let data):
        do {
          try AxisAssetWriter()
            .writeAsset(
              data,
              atURL: self.dedicatedWriteURL.appendingPathComponent(title))
          self.itemDownloaded()
        } catch {
          self.handler?(.failure(error))
          return
        }
      case .failure(let error):
        self.handler?(.failure(error))
        return
      }
    }
  }
  
  private func itemDownloaded() {
    DispatchQueue.main.async {
      self.itemsDownloadedCount = self.itemsDownloadedCount + 1
      if (self.itemsDownloadedCount == self.totalCountRequired) {
        self.handler?(.success(true))
      }
    }
  }
  
  
}



struct AxisContainerDownloader {
  let containerURL: URL
  let dedicatedDownloadURL: URL
  
  func downloadContainer(_ completion: @escaping (Result<Bool, Error>) -> Void) {
    
    let downloadError = NSError(domain: "Failed downloading container",
                                code: 500,
                                userInfo: nil)
    
    _ = NYPLNetworkExecutor.shared.GET(containerURL) { (data, response, error) in
      if let error = error {
        completion(.failure(error))
        return
      }
      
      if let response = response as? HTTPURLResponse,
        !(200...299).contains(response.statusCode) {
        completion(.failure(downloadError))
        return
      }
      
      if let data = data {
        do {
          try AxisAssetWriter().writeAsset(data, atURL: self.dedicatedDownloadURL)
          completion(.success(true))
        } catch {
          completion(.failure(error))
        }
        
        return
      }
      
      completion(.failure(downloadError))
    }
  }
}

struct AxisLicenseURLGenerator {
  let isbn: String
  let bookVaultId: String
  
  var licenseURL: URL? {
    guard let rsa = NYPLRSACypher() else {
      return nil
    }
    
    let modulus = rsa.publicKey.replacingOccurrences(of: "/", with: "-")
    let exponent = "AQAB"
    let baseURL = URL(string: "https://node.axisnow.com/license")!
    // TODO: Fix this
    let deviceId: String = UUID().uuidString
    let clientIp = "192.168.0.1"
    let licenseURL = baseURL
      .appendingPathComponent(bookVaultId)
      .appendingPathComponent(deviceId)
      .appendingPathComponent(clientIp)
      .appendingPathComponent(isbn)
      .appendingPathComponent(modulus)
      .appendingPathComponent(exponent)
    
    return licenseURL
  }
  
}

struct AxisContentDownloader {
  
  func downloadContent(from url: URL,
                       completion: @escaping (Result<Data, Error>) -> Void) {
    
    let downloadError = NSError(domain: "Failed downloading license",
                                code: 500,
                                userInfo: nil)
    
    _ = NYPLNetworkExecutor.shared.GET(url) { (data, response, error) in
      if let error = error {
        completion(.failure(error))
        return
      }
      
      if let response = response as? HTTPURLResponse,
        !(200...299).contains(response.statusCode) {
        completion(.failure(downloadError))
        return
      }
      
      if let data = data {
        completion(.success(data))
        return
      }
      
      completion(.failure(downloadError))
    }
  }
  
}

struct AxisAssetWriter {

  func writeAsset(_ data: Data, atURL url: URL) throws {
    let folderURL = url.deletingLastPathComponent()
    let dirExists = FileManager.default.fileExists(atPath: folderURL.path)
    if (!dirExists) {
      try FileManager.default.createDirectory(at: folderURL,
                                              withIntermediateDirectories: true,
                                              attributes: nil)
    }

    try data.write(to: url)
  }

}
