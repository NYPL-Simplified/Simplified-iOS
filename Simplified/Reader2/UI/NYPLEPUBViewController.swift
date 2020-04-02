//
//  NYPLEPUBViewController.swift
//
//  Created by Alexandre Camilleri on 7/3/17.
//
//  Copyright 2018 European Digital Reading Lab. All rights reserved.
//  Licensed to the Readium Foundation under one or more contributor license agreements.
//  Use of this source code is governed by a BSD-style license which is detailed in the
//  LICENSE file present in the project repository where this source code is maintained.
//

import UIKit
import R2Shared
import R2Navigator

class NYPLEPUBViewController: ReaderViewController {
  
  var popoverUserconfigurationAnchor: UIBarButtonItem?

  // TODO: SIMPLY-2656 Remove once R2 work is complete
  var userSettingNavigationController: UserSettingsNavigationController

  init(publication: Publication, book: NYPLBook, drm: DRM?, resourcesServer: ResourcesServer) {
    let navigator = EPUBNavigatorViewController(publication: publication, license: drm?.license, initialLocation: book.progressionLocator, resourcesServer: resourcesServer)

    let settingsStoryboard = UIStoryboard(name: "UserSettings", bundle: nil)
    userSettingNavigationController = settingsStoryboard.instantiateViewController(withIdentifier: "UserSettingsNavigationController") as! UserSettingsNavigationController
    userSettingNavigationController.fontSelectionViewController =
      (settingsStoryboard.instantiateViewController(withIdentifier: "FontSelectionViewController") as! FontSelectionViewController)
    userSettingNavigationController.advancedSettingsViewController =
      (settingsStoryboard.instantiateViewController(withIdentifier: "AdvancedSettingsViewController") as! AdvancedSettingsViewController)

    super.init(navigator: navigator, publication: publication, book: book, drm: drm)

    navigator.delegate = self
  }

  var epubNavigator: EPUBNavigatorViewController {
    return navigator as! EPUBNavigatorViewController
  }

  override func willMove(toParent parent: UIViewController?) {
    super.willMove(toParent: parent)

    // Restore catalog default UI colors
    navigationController?.navigationBar.barStyle = .default
    navigationController?.navigationBar.barTintColor = nil
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    userSettingNavigationController.userSettings = userSettings.r2UserSettings
    userSettingNavigationController.modalPresentationStyle = .popover
    userSettingNavigationController.usdelegate = self
    userSettingNavigationController.userSettingsTableViewController.publication = publication


    publication.userSettingsUIPresetUpdated = { [weak self] preset in
      guard let `self` = self, let presetScrollValue:Bool = preset?[.scroll] else {
        return
      }

      if let scroll = self.userSettingNavigationController.userSettings.userProperties.getProperty(reference: ReadiumCSSReference.scroll.rawValue) as? Switchable {
        if scroll.on != presetScrollValue {
          self.userSettingNavigationController.scrollModeDidChange()
        }
      }
    }
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.applyCurrentSettings()
  }

  override open func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    userSettings.save()
  }

  override func makeNavigationBarButtons() -> [UIBarButtonItem] {
    var buttons = super.makeNavigationBarButtons()

    // User configuration button
    let userSettingsButton = UIBarButtonItem(image: UIImage(named: "Format"),
                                             style: .plain,
                                             target: self,
                                             action: #selector(presentUserSettings))
    buttons.insert(userSettingsButton, at: 1)
    popoverUserconfigurationAnchor = userSettingsButton

    return buttons
  }

  // TODO: SIMPLY-2608
//  override var currentBookmark: Bookmark? {
//    guard let publicationID = publication.metadata.identifier,
//      let locator = navigator.currentLocation,
//      let resourceIndex = publication.readingOrder.firstIndex(withHref: locator.href) else
//    {
//      return nil
//    }
//    return Bookmark(publicationID: publicationID, resourceIndex: resourceIndex, locator: locator)
//  }

  @objc func presentUserSettings() {
    // TODO: SIMPLY-2626: publication is used to handle changes related to
    // page margins, line height, word/letter spacing, columnar layout, text
    // alignment
    userSettingNavigationController.publication = publication

    let vc = NYPLUserSettingsVC(delegate: self)
    vc.modalPresentationStyle = .popover
    vc.popoverPresentationController?.delegate = self
    vc.popoverPresentationController?.barButtonItem = popoverUserconfigurationAnchor

    present(vc, animated: true) {
      // Makes sure that the popover is dismissed also when tapping on one of
      // the other UIBarButtonItems.
      // ie. http://karmeye.com/2014/11/20/ios8-popovers-and-passthroughviews/
      vc.popoverPresentationController?.passthroughViews = nil
    }
  }
}

// MARK: - NYPLUserSettingsReaderDelegate

extension NYPLEPUBViewController: NYPLUserSettingsReaderDelegate {
  var userSettings: NYPLR1R2UserSettings {
    return NYPLR1R2UserSettings(r2UserSettings: epubNavigator.userSettings)
  }

  func applyCurrentSettings() {
    NYPLMainThreadRun.asyncIfNeeded {
      if let appearance = self.userSettings.r2UserSettings?.userProperties.getProperty(reference: ReadiumCSSReference.appearance.rawValue) as? Enumerable {

        let colors = NYPLR1R2UserSettings.colors(for: appearance)
        self.navigator.view.backgroundColor = colors.backgroundColor
        self.view.backgroundColor = colors.backgroundColor
        self.navigationController?.navigationBar.barTintColor = colors.backgroundColor
      }

      switch self.userSettings.r1UserSettings.colorScheme {
      case .blackOnSepia:
        self.navigationController?.navigationBar.barStyle = .default
      case .blackOnWhite:
        self.navigationController?.navigationBar.barStyle = .default
      case .whiteOnBlack:
        self.navigationController?.navigationBar.barStyle = .black
      }

      self.epubNavigator.updateUserSettingStyle()
    }
  }
}

// MARK: - EPUBNavigatorDelegate

extension NYPLEPUBViewController: EPUBNavigatorDelegate {
}

// MARK: - UIGestureRecognizerDelegate

extension NYPLEPUBViewController: UIGestureRecognizerDelegate {
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
}

// MARK: - UIPopoverPresentationControllerDelegate

extension NYPLEPUBViewController: UIPopoverPresentationControllerDelegate {
  // Prevent the popOver to be presented fullscreen on iPhones.
  func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle
  {
    return .none
  }
}
