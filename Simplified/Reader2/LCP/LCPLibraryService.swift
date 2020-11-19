//
//  LCPLibraryService.swift
//  r2-testapp-swift
//
//  Created by Mickaël Menu on 01.02.19.
//
//  Copyright 2019 Readium Foundation. All rights reserved.
//  Use of this source code is governed by a BSD-style license which is detailed
//  in the LICENSE file present in the project repository where this source code is maintained.
//

#if LCP

import Foundation
import UIKit
import R2Shared
import ReadiumLCP


@objc class LCPLibraryService: NSObject, DRMLibraryService {
  
  private var lcpService =  R2MakeLCPService()
  
  /// [LicenseDocument.id: passphrase callback]
  private var authenticationCallbacks: [String: (String?) -> Void] = [:]
  
  /// Library service brand
  var brand: DRM.Brand {
    return .lcp
  }
  
  /// Returns whether this DRM can fulfill the given file into a protected publication.
  /// - Parameter file: file URL
  /// - Returns: `true` if file contains LCP DRM license information.
  func canFulfill(_ file: URL) -> Bool {
    return file.pathExtension.lowercased() == "lcpl"
  }
  
  /// Fulfill LCP license publication
  /// This function was added for compatibility with Objective-C NYPLMyBooksDownloadCenter.
  /// - Parameters:
  ///   - file: LCP license file.
  ///   - completion: Complition is called after a publication was downloaded or an error received.
  ///   - localUrl: Downloaded publication URL.
  ///   - downloadTask: `URLSessionDownloadTask` that downloaded the publication.
  ///   - error: `NSError` if any.
  @objc func fulfill(_ file: URL, completion: @escaping (_ localUrl: URL?, _ downloadTask: URLSessionDownloadTask?, _ error: NSError?) -> Void) {
    lcpService.importPublication(from: file, authentication: self) { result, error in
      var nsError: NSError?
      if let error = error {
        let domain = "LCP fulfillment error"
        let code = 0
        nsError = NSError(domain: domain, code: code, userInfo: [
          NSLocalizedDescriptionKey: error.errorDescription as Any
        ])
      }
      completion(result?.localURL, result?.downloadTask, nsError)
    }
  }
  
  /// Fulfills the given file to the fully protected publication.
  /// - Parameters:
  ///   - file: file URL
  ///   - completion: fulfilled publication, CancellableResult<DRMFulfilledPublication>
  func fulfill(_ file: URL, completion: @escaping (CancellableResult<DRMFulfilledPublication>) -> Void) {
    lcpService.importPublication(from: file, authentication: self) { result, error in
      if let result = result {
        let publication = DRMFulfilledPublication(localURL: result.localURL, downloadTask: result.downloadTask, suggestedFilename: result.suggestedFilename)
        completion(.success(publication))
      } else if let error = error {
        completion(.failure(error))
      } else {
        completion(.cancelled)
      }
    }
  }
  
  /// Fills the DRM context of the given protected publication.
  /// - Parameters:
  ///   - publication: file URL
  ///   - drm: DRM
  ///   - completion: result of retrieving a license for the publication, CancellableResult<DRM?>
  func loadPublication(at publication: URL, drm: DRM, completion: @escaping (CancellableResult<DRM?>) -> Void) {
    lcpService.retrieveLicense(from: publication, authentication: self) { license, error in
      if let license = license {
        var drm = drm
        drm.license = license
        completion(.success(drm))
      } else if let error = error {
        completion(.failure(error))
      } else {
        completion(.cancelled)
      }
    }
  }
  
}

extension LCPLibraryService: LCPAuthenticating {
  
  /// Requests a passphrase to decrypt the given license.
  ///
  /// - Parameter license: Information to show to the user about the license being opened.
  /// - Parameter reason: Reason why the passphrase is requested. It should be used to prompt the user.
  /// - Parameter completion: Used to return the retrieved passphrase. If the user cancelled, send nil. The passphrase may
  ///   be already hashed.
  func requestPassphrase(for license: LCPAuthenticatedLicense, reason: LCPAuthenticationReason, completion: @escaping (String?) -> Void) {
    guard let viewController = UIApplication.shared.keyWindow?.rootViewController?.presentedViewController ?? UIApplication.shared.keyWindow?.rootViewController else {
      completion(nil)
      return
    }
    
    authenticationCallbacks[license.document.id] = completion
    
    let licenseInfo = LCPLicenseInfo(license: license)
    let authenticationVC = LCPAuthenticationViewController(licenseInfo: licenseInfo, reason: reason)
    authenticationVC.delegate = self
    
    let navController = UINavigationController(rootViewController: authenticationVC)
    navController.modalPresentationStyle = .formSheet
    
    viewController.present(navController, animated: true)
  }
  
}


extension LCPLibraryService: LCPAuthenticationDelegate {
  
  /// Authenticate with passphrase.
  /// The function calls the callback set for document ID in the license
  /// - Parameters:
  ///   - license: Information to show to the user about the license being opened.
  ///   - passphrase: License passphrase
  func authenticate(_ license: LCPAuthenticatedLicense, with passphrase: String) {
    guard let callback = authenticationCallbacks.removeValue(forKey: license.document.id) else {
      return
    }
    callback(passphrase)
  }
  
  /// Cancel authentication. The function removes authentication callback associated with the license document ID
  /// - Parameter license:Information to show to the user about the license being opened.
  func didCancelAuthentication(of license: LCPAuthenticatedLicense) {
    guard let callback = authenticationCallbacks.removeValue(forKey: license.document.id) else {
      return
    }
    callback(nil)
  }
  
}

#endif
