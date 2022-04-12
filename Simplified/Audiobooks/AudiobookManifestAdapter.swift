//
//  AudiobookManifestHelper.swift
//  Simplified
//
//  Created by Ernest Fan on 2022-03-30.
//  Copyright © 2022 NYPL. All rights reserved.
//
#if FEATURE_AUDIOBOOKS

import Foundation
import NYPLAudiobookToolkit
import UIKit

#if FEATURE_OVERDRIVE_AUTH
import OverdriveProcessor
#endif

@objc enum AudiobookManifestError: Int {
  case none
  case unsupported
  case corrupted
}

@objc class AudiobookManifestAdapter: NSObject {
  @objc class func transformAudiobookManifest(book: NYPLBook,
                                              completion: @escaping (_ manifest: [String: Any]?,
                                                                     _ decryptor: DRMDecryptor?,
                                                                     _ error: AudiobookManifestError) -> Void)
  {
    guard let url = NYPLMyBooksDownloadCenter.shared().fileURL(forBookIndentifier: book.identifier),
          let data = try? Data.init(contentsOf: url),
          let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            completion(nil, nil, .corrupted)
            return
          }
    var dict: [String: Any] = json
#if FEATURE_OVERDRIVE_AUTH
    if (book.distributor == OverdriveAPI.distributorKey) {
      dict["id"] = book.identifier
    }
#endif
    
#if LCP
    if LCPAudiobooks.canOpenBook(book) {
      let lcpAudiobook = LCPAudiobooks.init(for: url)
      lcpAudiobook?.contentDictionary(completion: { dict, error in
        if (error) {
          completion(nil, nil, .unsupported)
        }
        
        if dict != nil {
          var updatedManifest = dict
          updatedManifest["id"] = book.identifier
          completion(updatedManifest, lcpAudiobook, .none)
        }
      })
    }
#endif
    
    completion(dict, nil, .none)
  }
}

#endif
