//
//  ReaderViewController.swift
//  Created by Mickaël Menu on 07.03.19.
//
//  Copyright 2019 European Digital Reading Lab. All rights reserved.
//  Licensed to the Readium Foundation under one or more contributor license agreements.
//  Use of this source code is governed by a BSD-style license which is detailed in the
//  LICENSE file present in the project repository where this source code is maintained.
//

import SafariServices
import UIKit
import R2Navigator
import R2Shared


/// This class is meant to be subclassed by each publication format view controller. It contains the shared behavior, eg. navigation bar toggling.
class NYPLBaseReaderViewController: UIViewController, Loggable {

  private static let bookmarkOnImageName = "BookmarkOn"
  private static let bookmarkOffImageName = "BookmarkOff"

  // TODO: SIMPLY-2656 See if we still need this.
  weak var moduleDelegate: ModuleDelegate?

  // Models and business logic references
  let publication: Publication
  private let bookmarksBusinessLogic: NYPLReaderBookmarksBusinessLogic
  private let lastReadPositionPoster: NYPLLastReadPositionPoster

  // UI
  let navigator: UIViewController & Navigator
  private var tocBarButton: UIBarButtonItem?
  private var bookmarkBarButton: UIBarButtonItem?
  private(set) var stackView: UIStackView!
  private lazy var positionLabel = UILabel()

  // MARK: - Lifecycle

  /// Designated initializer.
  /// - Parameters:
  ///   - navigator: VC that is capable of navigating the publication.
  ///   - publication: The R2 model for a publication.
  ///   - book: The SimplyE model for a book.
  ///   - drm: Information about the DRM associated with the publication.
  init(navigator: UIViewController & Navigator,
       publication: Publication,
       book: NYPLBook) {

    self.navigator = navigator
    self.publication = publication

    lastReadPositionPoster = NYPLLastReadPositionPoster(
      book: book,
      bookRegistryProvider: NYPLBookRegistry.shared())

    bookmarksBusinessLogic = NYPLReaderBookmarksBusinessLogic(
      book: book,
      r2Publication: publication,
      drmDeviceID: NYPLUserAccount.sharedAccount().deviceID,
      bookRegistryProvider: NYPLBookRegistry.shared(),
      currentLibraryAccountProvider: AccountsManager.shared)

    bookmarksBusinessLogic.syncBookmarks { (_, _) in }

    super.init(nibName: nil, bundle: nil)

    NotificationCenter.default.addObserver(self, selector: #selector(voiceOverStatusDidChange), name: Notification.Name(UIAccessibilityVoiceOverStatusChanged), object: nil)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  // MARK: - UIViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = NYPLConfiguration.backgroundColor()

    navigationItem.rightBarButtonItems = makeNavigationBarButtons()
    updateNavigationBar(animated: false)

    stackView = UIStackView(frame: view.bounds)
    stackView.distribution = .fill
    stackView.axis = .vertical
    view.addSubview(stackView)
    stackView.translatesAutoresizingMaskIntoConstraints = false
    let topConstraint = stackView.topAnchor.constraint(equalTo: view.topAnchor)
    // `accessibilityTopMargin` takes precedence when VoiceOver is enabled.
    topConstraint.priority = .defaultHigh
    NSLayoutConstraint.activate([
      topConstraint,
      stackView.rightAnchor.constraint(equalTo: view.rightAnchor),
      stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      stackView.leftAnchor.constraint(equalTo: view.leftAnchor)
    ])

    addChild(navigator)
    stackView.addArrangedSubview(navigator.view)
    navigator.didMove(toParent: self)

    stackView.addArrangedSubview(accessibilityToolbar)

    positionLabel.translatesAutoresizingMaskIntoConstraints = false
    positionLabel.font = .systemFont(ofSize: 12)
    positionLabel.textColor = .darkGray
    view.addSubview(positionLabel)
    NSLayoutConstraint.activate([
      positionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      positionLabel.bottomAnchor.constraint(equalTo: navigator.view.bottomAnchor, constant: -20)
    ])
  }

  override func willMove(toParent parent: UIViewController?) {
    super.willMove(toParent: parent)

    if parent == nil {
      NYPLBookRegistry.shared().save()
    }
  }


  // MARK: - Navigation bar

  private var navigationBarHidden: Bool = true {
    didSet {
      updateNavigationBar()
    }
  }

  func makeNavigationBarButtons() -> [UIBarButtonItem] {
    var buttons: [UIBarButtonItem] = []

    let img = UIImage(named: NYPLBaseReaderViewController.bookmarkOffImageName)
    let bookmarkBtn = UIBarButtonItem(image: img,
                                      style: .plain,
                                      target: self,
                                      action: #selector(toggleBookmark))

    let tocButton = UIBarButtonItem(image: UIImage(named: "TOC"),
                                    style: .plain,
                                    target: self,
                                    action: #selector(presentPositionsVC))
    buttons.append(bookmarkBtn)
    buttons.append(tocButton)
    tocBarButton = tocButton
    bookmarkBarButton = bookmarkBtn
    updateBookmarkButton(withState: false)

    return buttons
  }

  private func updateBookmarkButton(withState isOn: Bool) {
    guard let btn = bookmarkBarButton else {
      return
    }

    if isOn {
      btn.image = UIImage(named: NYPLBaseReaderViewController.bookmarkOnImageName)
      btn.accessibilityLabel = NSLocalizedString("Remove Bookmark",
                                                 comment: "Accessibility label for button to remove a bookmark")
    } else {
      btn.image = UIImage(named: NYPLBaseReaderViewController.bookmarkOffImageName)
      btn.accessibilityLabel = NSLocalizedString("Add Bookmark",
                                                 comment: "Accessibility label for button to add a bookmark")
    }
  }

  func toggleNavigationBar() {
    navigationBarHidden = !navigationBarHidden
  }

  func updateNavigationBar(animated: Bool = true) {
    let hidden = navigationBarHidden && !UIAccessibility.isVoiceOverRunning
    navigationController?.setNavigationBarHidden(hidden, animated: animated)
    setNeedsStatusBarAppearanceUpdate()
  }

  override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
    return .slide
  }

  override var prefersStatusBarHidden: Bool {
    return navigationBarHidden && !UIAccessibility.isVoiceOverRunning
  }

  //----------------------------------------------------------------------------
  // MARK: - TOC / Bookmarks

  private func shouldPresentAsPopover() -> Bool {
    return UIDevice.current.userInterfaceIdiom == .pad
  }

  @objc func presentPositionsVC() {
    let currentLocation = navigator.currentLocation
    let positionsVC = NYPLReaderPositionsVC.newInstance()

    positionsVC.tocBusinessLogic = NYPLReaderTOCBusinessLogic(r2Publication: publication,
                                                              currentLocation: currentLocation)
    positionsVC.bookmarksBusinessLogic = bookmarksBusinessLogic
    positionsVC.delegate = self

    if shouldPresentAsPopover() {
      positionsVC.modalPresentationStyle = .popover
      positionsVC.popoverPresentationController?.barButtonItem = tocBarButton
      present(positionsVC, animated: true) {
        // Makes sure that the popover is dismissed also when tapping on one of
        // the other UIBarButtonItems.
        // ie. http://karmeye.com/2014/11/20/ios8-popovers-and-passthroughviews
        positionsVC.popoverPresentationController?.passthroughViews = nil
      }
    } else {
      navigationController?.pushViewController(positionsVC, animated: true)
    }
  }

  @objc func toggleBookmark() {
    guard let loc = bookmarksBusinessLogic.currentLocation(in: navigator) else {
      return
    }

    if let bookmark = bookmarksBusinessLogic.bookmarkExisting(at: loc) {
      deleteBookmark(bookmark)
    } else {
      addBookmark(at: loc)
    }
  }

  private func addBookmark(at location: NYPLBookmarkR2Location) {
    guard let bookmark = bookmarksBusinessLogic.addBookmark(location) else {
      let alert = NYPLAlertUtils.alert(title: "Bookmarking Error",
                                       message: "A bookmark could not be created on the current page.")
      NYPLAlertUtils.presentFromViewControllerOrNil(alertController: alert,
                                                    viewController: self,
                                                    animated: true,
                                                    completion: nil)
      return
    }

    Log.info(#file, "Created bookmark: \(bookmark)")

    updateBookmarkButton(withState: true)
  }

  private func deleteBookmark(_ bookmark: NYPLReadiumBookmark) {
    bookmarksBusinessLogic.deleteBookmark(bookmark)
    didDeleteBookmark(bookmark)
  }

  private func didDeleteBookmark(_ bookmark: NYPLReadiumBookmark) {
    // at this point the bookmark has already been removed, so we just need
    // to verify that the user is not at the same location of another bookmark,
    // in which case the bookmark icon will be lit up and should stay lit up.
    if
      let loc = bookmarksBusinessLogic.currentLocation(in: navigator),
      bookmarksBusinessLogic.bookmarkExisting(at: loc) == nil {

      updateBookmarkButton(withState: false)
    }
  }

  //----------------------------------------------------------------------------
  // MARK: - Accessibility

  /// Constraint used to shift the content under the navigation bar, since it is always visible when VoiceOver is running.
  private lazy var accessibilityTopMargin: NSLayoutConstraint = {
    let topAnchor: NSLayoutYAxisAnchor = {
      if #available(iOS 11.0, *) {
        return self.view.safeAreaLayoutGuide.topAnchor
      } else {
        return self.topLayoutGuide.bottomAnchor
      }
    }()
    return self.stackView.topAnchor.constraint(equalTo: topAnchor)
  }()

  private lazy var accessibilityToolbar: UIToolbar = {
    func makeItem(_ item: UIBarButtonItem.SystemItem, label: String? = nil, action: UIKit.Selector? = nil) -> UIBarButtonItem {
      let button = UIBarButtonItem(barButtonSystemItem: item, target: (action != nil) ? self : nil, action: action)
      button.accessibilityLabel = label
      return button
    }

    let toolbar = UIToolbar(frame: .zero)
    toolbar.items = [
      makeItem(.flexibleSpace),
      makeItem(.rewind, label: NSLocalizedString("Previous Chapter", comment: "Accessibility label to go backward in the publication"), action: #selector(goBackward)),
      makeItem(.flexibleSpace),
      makeItem(.fastForward, label: NSLocalizedString("Next Chapter", comment: "Accessibility label to go forward in the publication"), action: #selector(goForward)),
      makeItem(.flexibleSpace),
    ]
    toolbar.isHidden = !UIAccessibility.isVoiceOverRunning
    toolbar.tintColor = UIColor.black
    return toolbar
  }()

  private var isVoiceOverRunning = UIAccessibility.isVoiceOverRunning

  @objc private func voiceOverStatusDidChange() {
    let isRunning = UIAccessibility.isVoiceOverRunning
    // Avoids excessive settings refresh when the status didn't change.
    guard isVoiceOverRunning != isRunning else {
      return
    }
    isVoiceOverRunning = isRunning
    accessibilityTopMargin.isActive = isRunning
    accessibilityToolbar.isHidden = !isRunning
    updateNavigationBar()
  }

  @objc private func goBackward() {
    navigator.goBackward()
  }

  @objc private func goForward() {
    navigator.goForward()
  }

}

//------------------------------------------------------------------------------
// MARK: - NavigatorDelegate

extension NYPLBaseReaderViewController: NavigatorDelegate {

  func navigator(_ navigator: Navigator, locationDidChange locator: Locator) {
    Log.info(#function, "R2 locator changed to: \(locator)")

    lastReadPositionPoster.storeReadPosition(locator: locator)

    positionLabel.text = {
      var chapterTitle = ""
      if let title = locator.title {
        chapterTitle = " (\(title))"
      }
      
      if let position = locator.locations.position {
        return "Page \(position) of \(publication.positions.count)" + chapterTitle
      } else if let progression = locator.locations.totalProgression {
        return "\(progression)%" + chapterTitle
      } else {
        return nil
      }
    }()
    
    if let resourceIndex = publication.resourceIndex(forLocator: locator),
      let _ = bookmarksBusinessLogic.bookmarkExisting(at: NYPLBookmarkR2Location(resourceIndex: resourceIndex, locator: locator)) {
      updateBookmarkButton(withState: true)
    } else {
      updateBookmarkButton(withState: false)
    }
  }

  func navigator(_ navigator: Navigator, presentExternalURL url: URL) {
    // SFSafariViewController crashes when given an URL without an HTTP scheme.
    guard ["http", "https"].contains(url.scheme?.lowercased() ?? "") else {
      return
    }
    present(SFSafariViewController(url: url), animated: true)
  }

  func navigator(_ navigator: Navigator, presentError error: NavigatorError) {
    moduleDelegate?.presentError(error, from: self)
  }

}

//------------------------------------------------------------------------------
// MARK: - VisualNavigatorDelegate

extension NYPLBaseReaderViewController: VisualNavigatorDelegate {

  func navigator(_ navigator: VisualNavigator, didTapAt point: CGPoint) {
    let viewport = navigator.view.bounds
    // Skips to previous/next pages if the tap is on the content edges.
    let thresholdRange = 0...(0.2 * viewport.width)
    var moved = false
    if thresholdRange ~= point.x {
      moved = navigator.goLeft(animated: false)
    } else if thresholdRange ~= (viewport.maxX - point.x) {
      moved = navigator.goRight(animated: false)
    }

    if !moved {
      toggleNavigationBar()
    }
  }

}

//------------------------------------------------------------------------------
// MARK: - NYPLReaderPositionsDelegate

extension NYPLBaseReaderViewController: NYPLReaderPositionsDelegate {
  func positionsVC(_ positionsVC: NYPLReaderPositionsVC, didSelectTOCLocation loc: Any) {
    if shouldPresentAsPopover() {
      positionsVC.dismiss(animated: true)
    } else {
      navigationController?.popViewController(animated: true)
    }

    if let location = loc as? Locator {
      navigator.go(to: location)
    }
  }

  func positionsVC(_ positionsVC: NYPLReaderPositionsVC,
                   didSelectBookmark bookmark: NYPLReadiumBookmark) {

    if shouldPresentAsPopover() {
      dismiss(animated: true)
    } else {
      navigationController?.popViewController(animated: true)
    }

    if let locator = bookmark.locator(forPublication: publication) {
      navigator.go(to: locator)
    }
  }

  func positionsVC(_ positionsVC: NYPLReaderPositionsVC,
                   didDeleteBookmark bookmark: NYPLReadiumBookmark) {
    didDeleteBookmark(bookmark)
  }

  func positionsVC(_ positionsVC: NYPLReaderPositionsVC,
                   didRequestSyncBookmarksWithCompletion completion: @escaping (_ success: Bool, _ bookmarks: [NYPLReadiumBookmark]) -> Void) {
    bookmarksBusinessLogic.syncBookmarks(completion: completion)
  }
}
