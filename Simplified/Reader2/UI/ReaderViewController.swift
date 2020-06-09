//
//  ReaderViewController.swift
//  r2-testapp-swift
//
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
class ReaderViewController: UIViewController, Loggable {

  weak var moduleDelegate: ReaderFormatModuleDelegate?

  let navigator: UIViewController & Navigator
  let publication: Publication
  let book: NYPLBook
  let drm: DRM?

  var tocBarButton: UIBarButtonItem?

  // TODO: SIMPLY-2608
//  lazy var bookmarksDataSource: BookmarkDataSource? = BookmarkDataSource(publicationID: publication.metadata.identifier ?? "")

  private(set) var stackView: UIStackView!
  private lazy var positionLabel = UILabel()

  init(navigator: UIViewController & Navigator, publication: Publication, book: NYPLBook, drm: DRM?) {
    self.navigator = navigator
    self.publication = publication
    self.book = book
    self.drm = drm

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

    buttons.append(UIBarButtonItem(image: UIImage(named: "BookmarkOff"),
                                   style: .plain,
                                   target: self,
                                   action: #selector(bookmarkCurrentPosition)))

    let tocButton = UIBarButtonItem(image: UIImage(named: "TOC"),
                                    style: .plain,
                                    target: self,
                                    action: #selector(presentTOC))
    buttons.append(tocButton)
    tocBarButton = tocButton

    // TODO: SIMPLY-2650 DRM management
//    if drm != nil {
//      buttons.append(UIBarButtonItem(image: #imageLiteral(resourceName: "drm"), style: .plain, target: self, action: #selector(presentDRMManagement)))
//    }
    // Bookmarks

    return buttons
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
  // MARK: - TOC

  private func shouldPresentAsPopover() -> Bool {
    return UIDevice.current.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass != .compact
  }

  @objc func presentTOC() {
    // for current location also see: https://github.com/readium/architecture/blob/master/models/locators/other/locator-api.md
    let currentLocation = navigator.currentLocation

    let positionsVC = NYPLReaderPositionsVC.newInstance()
    positionsVC.tocBusinessLogic = NYPLReaderTOCBusinessLogic(book: book, r2Publication: publication, currentLocation: currentLocation)
    positionsVC.bookmarksBusinessLogic = NYPLReaderBookmarksBusinessLogic(book: book, r2Publication: publication)
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

  // MARK: - Bookmarks

  // TODO: SIMPLY-2608
  //  var currentBookmark: Bookmark? {
  //    return nil
  //  }

  @objc func bookmarkCurrentPosition() {
    // TODO: SIMPLY-2608
//    guard let dataSource = bookmarksDataSource,
//      let bookmark = currentBookmark,
//      dataSource.addBookmark(bookmark: bookmark) else
//    {
//      toast(NSLocalizedString("reader_bookmark_failure_message", comment: "Error message when adding a new bookmark failed"), on: view, duration: 2)
//      return
//    }
//    toast(NSLocalizedString("reader_bookmark_success_message", comment: "Success message when adding a bookmark"), on: view, duration: 1)
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

extension ReaderViewController: NavigatorDelegate {

  func navigator(_ navigator: Navigator, locationDidChange locator: Locator) {
//    do {
//      //TODO: SIMPLY-2609
//      try BooksDatabase.shared.books.saveProgression(locator, of: book)
//    } catch {
//      log(.error, error)
//    }

    positionLabel.text = {
      if let position = locator.locations.position {
        return "\(position) / \(publication.positions.count)"
      } else if let progression = locator.locations.totalProgression {
        return "\(progression)%"
      } else {
        return nil
      }
    }()
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

extension ReaderViewController: VisualNavigatorDelegate {

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

extension ReaderViewController: NYPLReaderPositionsDelegate {
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

  func positionsVC(_ positionsVC: NYPLReaderPositionsVC, didSelectBookmark bookmark: NYPLReadiumBookmark) {
    // TODO: SIMPLY-2608
  }

  func positionsVC(_ positionsVC: NYPLReaderPositionsVC, didDeleteBookmark bookmark: NYPLReadiumBookmark) {
    // TODO: SIMPLY-2608
  }

  func positionsVC(_ positionsVC: NYPLReaderPositionsVC,
                   didRequestSyncBookmarksWithCompletion completion: (_ success: Bool, _ bookmarks: [NYPLReadiumBookmark]) -> Void) {
    // TODO: SIMPLY-2608
  }
}
