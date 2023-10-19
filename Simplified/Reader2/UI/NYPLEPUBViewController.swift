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

// =============================================================================
// MARK: - Workaround for VoiceOver Issues

/// Temporary workaround to continue using old UserSettings APIs in Readium.
/// 
/// Upgrading to the newer Preferences API requires also upgrading the
/// HTTP server from `PublicationServer` to `GCDHTTPServer`, but this exposes
/// some scrolling and navigating book content issues with VoiceOver.
/// By providing a way to cast to a non-deprecated protocol when access to the
/// deprecated apis is required, this workaround allows to silence the
/// deprecation warnings from Readium.
private protocol SettingsAccessing {
  var userSettings: UserSettings {get}
  func updateUserSettingStyle()
}

extension EPUBNavigatorViewController: SettingsAccessing {
}

fileprivate protocol EPUBNavigatorViewControllerMaking {
  func make(publication: Publication,
            initialLocation: Locator?,
            resourcesServer: ResourcesServer,
            config: EPUBNavigatorViewController.Configuration) -> EPUBNavigatorViewController
}

fileprivate class EPUBNavigatorViewControllerFactory: EPUBNavigatorViewControllerMaking {
  @available(*, deprecated, message: "To suppress this warning, cast to EPUBNavigatorViewControllerMaking protocol")
  fileprivate
  func make(publication: Publication,
            initialLocation: Locator?,
            resourcesServer: ResourcesServer,
            config: EPUBNavigatorViewController.Configuration) -> EPUBNavigatorViewController {
    EPUBNavigatorViewController(publication: publication,
                                initialLocation: initialLocation,
                                resourcesServer: resourcesServer,
                                config: config)
  }
}


// =============================================================================
// MARK: -

class NYPLEPUBViewController: NYPLBaseReaderViewController {
  
  var popoverUserconfigurationAnchor: UIBarButtonItem?

  let userSettings: NYPLR1R2UserSettings

  init(publication: Publication,
       book: NYPLBook,
       initialLocation: Locator?,
       resourcesServer: ResourcesServer,
       syncPermission: Bool,
       annotationsSynchronizer: NYPLAnnotationSyncing) {

    // - hyphens = true helps with layout on small screens especially when
    // publisher's defaults are off.
    // - publisher's defaults = false ensures that font size is changeable
    // even for EPUBs that specify a `fontSize: small` value in their CSS.
    // - paragraphMargins == 0.5 when VoiceOver is active ensures sufficient
    // separation between paragraphs so that when continuous reading is enabled
    // a swipe-right gesture does not skip to the end of the chapter instead
    // going to the next chapter as it should.
    let settings = UserSettings(hyphens: true,
                                publisherDefaults: false,
                                paragraphMargins: UIAccessibility.isVoiceOverRunning ? 0.5 : nil)

    // the "preload" settings were suggested by R2 engineers as a way to limit
    // the possible race conditions between restoring the initial location
    // without interfering with the web view layout timing
    // See: https://github.com/readium/r2-navigator-swift/issues/153
    let config = EPUBNavigatorViewController.Configuration(
        userSettings: settings,
        preloadPreviousPositionCount: 0,
        preloadNextPositionCount: 0,
        debugState: true)

    // when changing the type of the navigator, also change `epubNavigator` getter
    let factory: EPUBNavigatorViewControllerMaking = EPUBNavigatorViewControllerFactory()
    let navigator = factory.make(publication: publication,
                                 initialLocation: initialLocation,
                                 resourcesServer: resourcesServer,
                                 config: config)
    let navUserSettings = (navigator as SettingsAccessing).userSettings
    userSettings = NYPLR1R2UserSettings(r2UserSettings: navUserSettings)

    // EPUBNavigatorViewController::init creates a UserSettings object and sets
    // it into the publication. However, that UserSettings object will have the
    // defaults options for the various user properties (fonts etc), so we need
    // to re-set that to reflect our ad-hoc configuration.
    publication.userProperties = navUserSettings.userProperties

    super.init(navigator: navigator,
               publication: publication,
               book: book,
               syncPermission: syncPermission,
               annotationsSynchronizer: annotationsSynchronizer)

    navigator.delegate = self
  }

  fileprivate var epubNavigator: SettingsAccessing {
    return navigator as! EPUBNavigatorViewController
  }

  override func willMove(toParent parent: UIViewController?) {
    super.willMove(toParent: parent)

    // Restore catalog default UI colors
    navigationController?.navigationBar.barStyle = .default
    navigationController?.navigationBar.barTintColor = nil
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

  @objc func presentUserSettings() {
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
