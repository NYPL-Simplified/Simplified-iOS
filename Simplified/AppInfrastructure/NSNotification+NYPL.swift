//
//  NSNotification+NYPL.swift
//  Simplified
//
//  Created by Ettore Pasquini on 9/14/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

extension Notification.Name {
  static let NYPLSettingsDidChange = Notification.Name("NYPLSettingsDidChange")
  static let NYPLCurrentAccountDidChange = Notification.Name("NYPLCurrentAccountDidChange")
  static let NYPLCatalogDidLoad = Notification.Name("NYPLCatalogDidLoad")
  static let NYPLSyncBegan = Notification.Name("NYPLSyncBegan")
  static let NYPLSyncEnded = Notification.Name("NYPLSyncEnded")
  static let NYPLUseBetaDidChange = Notification.Name("NYPLUseBetaDidChange")
  static let NYPLUserAccountDidChange = Notification.Name("NYPLUserAccountDidChangeNotification")
  static let NYPLDidSignOut = Notification.Name("NYPLDidSignOut")

  // TODO: i think this was called "OEAppDelegateDidReceiveCleverRedirectURL"
  // in kyle's branch
  static let NYPLAppDelegateDidReceiveCleverRedirectURL = Notification.Name("NYPLAppDelegateDidReceiveCleverRedirectURL")
}

@objc extension NSNotification {
  public static let NYPLSettingsDidChange = Notification.Name.NYPLSettingsDidChange
  public static let NYPLCurrentAccountDidChange = Notification.Name.NYPLCurrentAccountDidChange
  public static let NYPLCatalogDidLoad = Notification.Name.NYPLCatalogDidLoad
  public static let NYPLSyncBegan = Notification.Name.NYPLSyncBegan
  public static let NYPLSyncEnded = Notification.Name.NYPLSyncEnded
  public static let NYPLUseBetaDidChange = Notification.Name.NYPLUseBetaDidChange
  public static let NYPLUserAccountDidChange = Notification.Name.NYPLUserAccountDidChange
  public static let NYPLDidSignOut = Notification.Name.NYPLDidSignOut
  public static let NYPLAppDelegateDidReceiveCleverRedirectURL = Notification.Name.NYPLAppDelegateDidReceiveCleverRedirectURL
}
