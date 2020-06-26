//
//  ACSLibraryService.swift
//  SimplyE
//
//  Created by Vladimir Fedorov on 13.05.2020.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation
import UIKit
import R2Shared

class ACSLibraryService: DRMLibraryService {
    
  /// Library service brand
  var brand: DRM.Brand {
    return .adobe
  }
  
  /// Returns whether this DRM can fulfill the given file into a protected publication.
  /// - Parameter file: file URL
  /// - Returns: Always returns true
  func canFulfill(_ file: URL) -> Bool {
    return true
  }
  
  /// Fulfills the given file to the fully protected publication.
  /// - Parameters:
  ///   - file: file URL
  ///   - completion: fulfilled publication, CancellableResult<DRMFulfilledPublication>
  func fulfill(_ file: URL, completion: @escaping (CancellableResult<DRMFulfilledPublication>) -> Void) {
    let publication = DRMFulfilledPublication(localURL: file, downloadTask: nil, suggestedFilename: "File Name")
    completion(.success(publication))
  }
  
  /// Fills the DRM context of the given protected publication.
  /// - Parameters:
  ///   - publication: file URL
  ///   - drm: DRM
  ///   - completion: result of retrieving a license for the publication, CancellableResult<DRM?>
  func loadPublication(at publication: URL, drm: DRM, completion: @escaping (CancellableResult<DRM?>) -> Void) {
    retrieveLicense(from: publication, authentication: self) { (license, error) in
      if let license = license {
        var drm = drm
        drm.license = license as DRMLicense
        completion(.success(drm))
      } else if let error = error {
        completion(.failure(error))
      } else {
        completion(.cancelled)
      }
    }
  }
  
  /// Retrieve license for the publication
  /// - Parameters:
  ///   - publication: file URL
  ///   - authentication: DRMLibraryService
  ///   - completion: license for the file, AdobeDRMLicense
  func retrieveLicense(from publication: URL, authentication: DRMLibraryService?, completion: (_ license: AdobeDRMLicense?, _ error: Error?) -> ()) {
    completion(AdobeDRMLicense(with: publication), nil)
  }
  
}
