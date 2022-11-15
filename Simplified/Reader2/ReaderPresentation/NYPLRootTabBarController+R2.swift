//
//  NYPLRootTabBarController+R2.swift
//  SimplyE
//
//  Created by Ettore Pasquini on 3/4/20.
//  Copyright © 2020 NYPL. All rights reserved.
//

import Foundation

@objc extension NYPLRootTabBarController {
  func presentBook(_ book: NYPLBook,
                   fromFileURL fileURL: URL?,
                   serverPermissions: NYPLReaderServerPermissions,
                   successCompletion: (() -> Void)?) {
    guard let libraryService = r2Owner?.libraryService, let readerModule = r2Owner?.readerModule else {
      return
    }

    libraryService.openBook(fromFileURL: fileURL, sender: self) { [weak self] result in
      guard let navVC = self?.selectedViewController as? UINavigationController else {
        preconditionFailure("No navigation controller, unable to present reader")
      }

      let drmDeviceID = NYPLUserAccount.sharedAccount().deviceID
      switch result {
      case .success(let publication):
        readerModule.presentPublication(publication,
                                        book: book,
                                        serverPermissions: serverPermissions,
                                        deviceID: drmDeviceID,
                                        in: navVC,
                                        successCompletion: successCompletion)
      case .cancelled:
        // .cancelled is returned when publication has restricted access to its resources and can't be rendered
        NYPLErrorLogger.logError(nil, summary: "Error accessing book resources", metadata: [
          "book": book.loggableDictionary
        ])
        let alertController = NYPLAlertUtils.alert(title: "ReaderViewControllerCorruptTitle", message: "ReaderViewControllerCorruptMessage")
        NYPLAlertUtils.presentFromViewControllerOrNil(alertController: alertController, viewController: self, animated: true, completion: nil)
        
      case .failure(let error):
        // .failure is retured for an error raised while trying to unlock publication
        // error is supposed to be visible to users, it is defined by ContentProtection error property
        NYPLErrorLogger.logError(error, summary: "Error accessing book resources", metadata: [
          "book": book.loggableDictionary
        ])
        let alertController = NYPLAlertUtils.alert(title: "Content Protection Error", message: error.localizedDescription)
        NYPLAlertUtils.presentFromViewControllerOrNil(alertController: alertController, viewController: self, animated: true, completion: nil)
      }
    }
  }
}

