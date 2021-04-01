//
//  AxisService.swift
//  Simplified
//
//  Created by Raman Singh on 2021-03-30.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

@objc protocol ObjectDownloading {
  
  func downloadObjectFromURL(_ url: URL, completion: (Data?, URLResponse?, Error?)->(Void))
}

@objc protocol AxisNowDelegate {
  func axisNowDidFinishDownload()
  func axisNowDownloadDidFail(withError error: Error?)
}

@objc
class AxisService: NSObject {
  
  private let isbn: String
  private let bookVaultId: String
  private let destinationURL: URL
  private weak var delegate: AxisNowDelegate?
  private let contentDownloader: AxisNowContentDownloading
  private var licenseDownloaded: Bool = false
  private var containerDownloaded: Bool = false
  private var encryptionDownloaded: Bool = false
  private var bookContentDownloaded: Bool = false
  private let assetWriter: AxisAssetWriting
  
  init(isbn: String,
       bookVaultId: String,
       destinationURL: URL,
       licenseDownloader: AxisNowContentDownloading,
       delegate: AxisNowDelegate?) {
    
    self.isbn = isbn
    self.bookVaultId = bookVaultId
    self.destinationURL = destinationURL
    self.delegate = delegate
    self.contentDownloader = licenseDownloader
    self.assetWriter = AxisAssetWriter()
    super.init()
  }
  
  @objc
  init?(fromFileAtURL fileURL: URL,
        destinationURL: URL,
        delegate: AxisNowDelegate?) {
    
    guard
      let licenseData = try? Data(contentsOf: fileURL),
      let jsonObject = try? JSONSerialization.jsonObject(with: licenseData, options: .fragmentsAllowed),
      let json = jsonObject as? [String: String],
      let isbn = json["isbn"],
      let bookVaultId = json["book_vault_uuid"]
      else {
        return nil
    }
    
    self.isbn = isbn
    self.bookVaultId = bookVaultId
    self.destinationURL = destinationURL
    self.delegate = delegate
    self.contentDownloader = AxisNowContentDownloader()
    self.assetWriter = AxisAssetWriter()
    super.init()
  }
  
  @objc
  func execute() {
    //        downloadLicense()
    downloadContainer()
    downloadEncryption()
    
    
    //        let data = try! Data(contentsOf: destinationURL.appendingPathComponent("encryption.xml"))
    //        let xml = NYPLXML(data: data)!
    //        startDownloadingContent(from: xml)
  }
  
  // MARK: - Download opf
  func downloadOPF(fromXML xml: NYPLXML) {
    let axisXML = AxisXML(xml: xml)
    let dummyError: NSError = NSError(domain: "", code: 2, userInfo: nil)
    guard
      let baseURL = getBaseURL(),
      let endpoint = axisXML.findRecursivelyInAttributes("full-path").first else {
        delegate?.axisNowDownloadDidFail(withError: dummyError)
        return
    }
    
    let downloadURL = baseURL.appendingPathComponent(endpoint)
    URLSession.shared.dataTask(with: downloadURL) { (data, response, error) in
      if let error = error {
        self.delegate?.axisNowDownloadDidFail(withError: error)
        return
      }
      guard let data = data else {
        self.delegate?.axisNowDownloadDidFail(withError: dummyError)
        return
      }
      
      let fileURL = self.destinationURL.appendingPathComponent(endpoint)
      try? self.assetWriter.writeAsset(data, atURL: fileURL)
      
      guard let xml = NYPLXML(data: data) else {
        self.delegate?.axisNowDownloadDidFail(withError: dummyError)
        return
      }
      let axisXML = AxisXML(xml: xml)
      self.downloadContentFromPackage(axisXML)
      
      
    }.resume()
  }
  
  func downloadContentFromPackage(_ axisXML: AxisXML) {
    
    let dummyError: NSError = NSError(domain: "", code: 2, userInfo: nil)
    guard
      let baseURL = getBaseURL(),
      let manifest = axisXML.children.filter({ $0.name == "manifest"}).first
      else {
        self.delegate?.axisNowDownloadDidFail(withError: dummyError)
        return
    }
    
    let hrefs = manifest.findRecursivelyInAttributes("href")
    for href in hrefs {
      let url = baseURL.appendingPathComponent("OEBPS").appendingPathComponent(href)
      URLSession.shared.dataTask(with: url) { (data, respone, error) in
        if let error = error {
          self.delegate?.axisNowDownloadDidFail(withError: error)
          return
        }
        guard let data = data else {
          self.delegate?.axisNowDownloadDidFail(withError: dummyError)
          return
        }
        
        let fileURL = self.destinationURL.appendingPathComponent(href)
        try? self.assetWriter.writeAsset(data, atURL: fileURL)
        
      }.resume()
    }
  }
  
  // MARK: - Download book content
  func startDownloadingContent(from xml: NYPLXML) {
    let endpaths = getCypherReferencesFromXML(xml)
    guard let baseURL = getBaseURL() else {
      return
    }
    
    endpaths.forEach { endpath in
      let downloadURL = baseURL.appendingPathComponent(endpath)
      print("content download url is \(downloadURL)")
      URLSession.shared.dataTask(with: downloadURL) { (data, response, error) in
        if let data = data {
          let fileURL = self.destinationURL.appendingPathComponent(endpath)
          try? self.assetWriter.writeAsset(data, atURL: fileURL)
        }
      }.resume()
    }
  }
  
  func getCypherReferencesFromXML(_ xml: NYPLXML) -> [String] {
    let axisXML = AxisXML(xml: xml)
    return axisXML.getCipherReferences
  }
  
  // MARK: - Download Encryption.xml
  func downloadEncryption() {
    let dummyError: NSError = NSError(domain: "", code: 2, userInfo: nil)
    guard let baseURL = getBaseURL() else {
      delegate?.axisNowDownloadDidFail(withError: dummyError)
      return
    }
    
    let encryptionURL = baseURL.appendingPathComponent("META-INF/encryption.xml")
    contentDownloader
      .downloadContent(
        from: encryptionURL,
        destination: destinationURL.appendingPathComponent("encryption.xml"),
        downloader: NYPLNetworkExecutor.shared) { (result) in
          switch result {
          case .success(let data):
            guard let xml = NYPLXML(data: data) else {
              self.delegate?.axisNowDownloadDidFail(withError: dummyError)
              return
            }
            
            //                        self.startDownloadingContent(from: xml)
            self.encryptionDownloaded = true
          case .failure(let error):
            self.delegate?.axisNowDownloadDidFail(withError: error)
          }
    }
  }
  
  // MARK: - Download Container.xml
  func downloadContainer() {
    let dummyError: NSError = NSError(domain: "", code: 2, userInfo: nil)
    guard let baseURL = getBaseURL() else {
      delegate?.axisNowDownloadDidFail(withError: dummyError)
      return
    }
    
    let containerURL = baseURL.appendingPathComponent("META-INF/container.xml")
    contentDownloader
      .downloadContent(
        from: containerURL,
        destination: destinationURL.appendingPathComponent("container.xml"),
        downloader: NYPLNetworkExecutor.shared) { (result) in
          switch result {
          case .success(let data):
            guard let xml = NYPLXML(data: data) else {
              self.delegate?.axisNowDownloadDidFail(withError: dummyError)
              return
            }
            
            self.downloadOPF(fromXML: xml)
            self.containerDownloaded = true
          case .failure(let error):
            self.delegate?.axisNowDownloadDidFail(withError: error)
          }
    }
  }
  
  private func getBaseURL() -> URL? {
    return URL(string: "https://node.axisnow.com/content/stream/\(self.isbn)/")
  }
  
  // MARK: - Download License
  
  private func downloadLicense() {
    let dummyError: NSError = NSError(domain: "", code: 2, userInfo: nil)
    guard let licenseURL = generateLicenseDownloadURL() else {
      delegate?.axisNowDownloadDidFail(withError: dummyError)
      return
    }
    
    contentDownloader
      .downloadContent(
        from: licenseURL,
        destination: destinationURL.appendingPathComponent("license.json"),
        downloader: NYPLNetworkExecutor.shared) { (result) in
          switch result {
          case .success:
            print("license downloaded successfully")
            self.licenseDownloaded = true
          case .failure(let error):
            self.delegate?.axisNowDownloadDidFail(withError: error)
          }
    }
  }
  
  private func generateLicenseDownloadURL() -> URL? {
    guard let rsa = RSAManager() else {
      return nil
    }
    
    let modulus = rsa.getPublicKey().replacingOccurrences(of: "/", with: "-")
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
  
  // MARK: - Final step
  func itemDownloaded() {
    
  }
  
  deinit {
    print("oops!")
  }
}


protocol AxisNowContentDownloading {
  func downloadContent(from url: URL,
                       destination: URL,
                       downloader: NYPLRequestExecuting,
                       completion: @escaping (Result<Data, Error>) -> Void)
}

struct AxisNowContentDownloader: AxisNowContentDownloading {
  
  func downloadContent(from url: URL,
                       destination: URL,
                       downloader: NYPLRequestExecuting,
                       completion: @escaping (Result<Data, Error>) -> Void) {
    
    let dummyError: NSError = NSError(domain: "", code: 2, userInfo: nil)
    let request = URLRequest(url: url)
    
    downloader.executeRequest(request) { (result) in
      switch result {
      case .success(let data, let response):
        guard
          let response = response as? HTTPURLResponse,
          (200...299).contains(response.statusCode)
          else {
            completion(.failure(dummyError))
            return
        }
        
        do {
          try data.write(to: destination)
          completion(.success(data))
        } catch {
          completion(.failure(error))
        }
      case .failure(let error, _):
        completion(.failure(error))
      }
    }
  }
  
}
