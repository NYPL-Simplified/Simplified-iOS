//
//  NYPLAxisProtectedAssetHandler.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-05-18.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
import R2Shared
import R2Streamer


typealias ProtectedAssetCompletion = (Result<ProtectedAsset, Publication.OpeningError>) -> Void

protocol NYPLAxisProtectedAssetHandling {
  func handleAsset(asset: FileAsset, fetcher: Fetcher,
                   completion: @escaping ProtectedAssetCompletion)
}

struct NYPLAxisProtectedAssetHandler: NYPLAxisProtectedAssetHandling {
  
  private let axisKeysProvider: NYPLAxisKeysProviding
  private let decryptor: NYPLAxisContentDecrypting
  private let licenseDownloader: NYPLAxisItemDownloading
  
  init(
    axisKeysProvider: NYPLAxisKeysProviding = NYPLAxisKeysProvider(),
    decryptor: NYPLAxisContentDecrypting,
    licenseDownloader: NYPLAxisItemDownloading = NYPLAxisItemDownloader()) {
    
    self.axisKeysProvider = axisKeysProvider
    self.decryptor = decryptor
    self.licenseDownloader = licenseDownloader
  }
  
  init?(axisKeysProvider: NYPLAxisKeysProviding = NYPLAxisKeysProvider(),
        decryptor: NYPLAxisContentDecrypting? = NYPLAxisContentDecryptor(),
        licenseDownloader: NYPLAxisItemDownloading = NYPLAxisItemDownloader()) {
    
    guard let decryptor = decryptor else {
      return nil
    }
    
    self.axisKeysProvider = axisKeysProvider
    self.decryptor = decryptor
    self.licenseDownloader = licenseDownloader
  }
  
  func handleAsset(asset: FileAsset, fetcher: Fetcher,
                   completion: @escaping ProtectedAssetCompletion) {
    
    downloadLicenseAndExtractKey(for: asset) { (result) in
      switch result {
      case .success(let key):
        transform(asset: asset, key: key, fetcher: fetcher, completion: completion)
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
  /// Downloads license file for the given book, validates it, extracts encrypted `AES` key, and decrypts it
  /// using our private key.
  ///
  /// - Note:
  /// We need to download license every time the user attempts to open book for reading. Upon downloading
  /// the license, we validate it and extract the encrypted `AES` key for unlocking content. The key itself
  /// needs to be decrypted before it can be used.
  ///
  /// - Parameters:
  ///   - asset: File Asset (NYPLBook file)
  ///   - completion: Decrypted `AES` key or `Publication.OpeningError`
  private func downloadLicenseAndExtractKey(
    for asset: FileAsset,
    completion: @escaping (Result<Data, Publication.OpeningError>) -> Void) {
    
    let bookInfoURL = asset.url.appendingPathComponent(axisKeysProvider.bookFilePathKey)
    guard
      let bookInfoData = try? Data(contentsOf: bookInfoURL),
      let jsonObject = try? JSONSerialization.jsonObject(
        with: bookInfoData, options: .fragmentsAllowed) as? [String: Any],
      let bookVaultId = jsonObject?[axisKeysProvider.bookVaultKey] as? String,
      let isbn = jsonObject?[axisKeysProvider.isbnKey] as? String
    else {
      completion(.failure(.notFound))
      return
    }
    
    let license = NYPLAxisLicenseService(axisItemDownloader: licenseDownloader,
                                         axisKeysProvider: axisKeysProvider,
                                         bookVaultId: bookVaultId,
                                         cypher: decryptor.cypher,
                                         isbn: isbn,
                                         parentDirectory: asset.url)
    
    let aggregator = NYPLAxisTaskAggregator()
    let tasks = [license.makeDownloadLicenseTask(), license.makeValidateLicenseTask()]
    aggregator
      .addTasks(tasks)
      .run()
      .onCompletion { (result) in
        switch result {
        case .success:
          guard
            let encryptedAESKey = license.encryptedContentKeyData(),
            let decryptedAESKey = decryptor.decryptAESKey(from: encryptedAESKey)
          else {
            license.makeDeleteLicenseTask().execute { _ in }
            completion(.failure(.forbidden(nil)))
            return
          }
          
          completion(.success(decryptedAESKey))
        case .failure:
          completion(.failure(.forbidden(nil)))
        }
      }
  }
  
  
  /// Decrypts encrypted content on demand
  /// - Parameters:
  ///   - asset: File Asset (NYPLBook file)
  ///   - key: AES key provided by Axis to unlock book content
  ///   - completion: ProtectedAsset Tuple or `Publication.OpeningError`
  private func transform(asset: FileAsset, key: Data, fetcher: Fetcher,
                         completion: ProtectedAssetCompletion) {
    
    let transformingFetcher = TransformingFetcher(fetcher: fetcher) {
      return decryptor.decrypt(resource: $0, withKey: key)
    }
    
    let protectedAsset = ProtectedAsset(asset: asset,
                                        fetcher: transformingFetcher,
                                        onCreatePublication: nil)
    completion(.success(protectedAsset))
  }
  
}

