//
//  NYPLLibraryFinderViewController.swift
//  Simplified
//
//  Created by Ernest Fan on 2021-04-21.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import UIKit

private enum NYPLLibraryFinderSection: Int, CaseIterable {
  case searchBar = 0
  case myLibrary
  case newLibrary
}

class NYPLLibraryFinderViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
  var isMyLibraryHidden = false
  
  private let dataProvider: NYPLLibraryFinderDataProviding
  private var completion: (Account) -> ()
  
  init(dataProvider: NYPLLibraryFinderDataProviding, completion: @escaping (Account) -> ()) {
    self.dataProvider = dataProvider
    self.completion = completion
    
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .vertical
    super.init(collectionViewLayout: layout)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    registerCollectionViewCell()
    setupCollectionViewUI()
    setupActivityIndicator()
  }
  
  // MARK: - CollectionView DataSource
  
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return NYPLLibraryFinderSection.allCases.count
  }

  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    collectionView.deselectItem(at: indexPath, animated: true)
    
    if indexPath.section == NYPLLibraryFinderSection.newLibrary.rawValue {
      let account = dataProvider.newLibraryAccounts[indexPath.item]
      completion(account)
    }
  }

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    guard let sectionType = NYPLLibraryFinderSection(rawValue: section) else {
      return 0
    }
    switch sectionType {
    case .searchBar:
      return 0
    case .myLibrary:
      return isMyLibraryHidden ? 0 : dataProvider.userAccounts.count
    case .newLibrary:
      return dataProvider.newLibraryAccounts.count
    }
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NYPLLibraryFinderLibraryCell.reuseId, for: indexPath) as? NYPLLibraryFinderLibraryCell,
      let sectionType = NYPLLibraryFinderSection.init(rawValue: indexPath.section) else {
      return UICollectionViewCell()
    }
    switch sectionType {
    case .myLibrary:
      let account = dataProvider.userAccounts[indexPath.item]
      cell.configureCell(type: .myLibrary, account: account)
    case .newLibrary:
      let account = dataProvider.newLibraryAccounts[indexPath.item]
      cell.configureCell(type: .newLibrary, account: account)
    default:
      break
    }
    return cell
  }
  
  // MARK: - FlowLayout
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return section == NYPLLibraryFinderSection.myLibrary.rawValue ? 0 : 8
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
    if section == NYPLLibraryFinderSection.newLibrary.rawValue && dataProvider.newLibraryAccounts.count == 0 {
      return CGSize.zero
    }
    return CGSize(width: collectionView.bounds.width - (NYPLLibraryFinderConfiguration.collectionViewContentInset * 2), height: 50)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
    var height: CGFloat = 0.0
    if section == NYPLLibraryFinderSection.myLibrary.rawValue {
      height = 10.0
    }
    return CGSize(width: collectionView.bounds.width - NYPLLibraryFinderConfiguration.collectionViewContentInset * 2, height: height)
  }
  
  override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    if indexPath.section == NYPLLibraryFinderSection.searchBar.rawValue {
      let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: searchBar.reuseId, for: indexPath)
      view.addSubview(searchBar)
      searchBar.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0))
      return view
    }
    
    if kind == UICollectionView.elementKindSectionHeader,
      let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                   withReuseIdentifier: NYPLLibraryFinderSectionHeaderView.reuseId,
                                                                   for: indexPath) as? NYPLLibraryFinderSectionHeaderView {
      let type: NYPLLibraryFinderLibraryCellType = indexPath.section == NYPLLibraryFinderSection.myLibrary.rawValue ? .myLibrary : .newLibrary
      return header.configured(for: type, displayer: self)
    }
    
    if kind == UICollectionView.elementKindSectionFooter {
      return collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                             withReuseIdentifier: NYPLLibraryFinderSectionFooterView.reuseId,
                                                             for: indexPath)
    }
    
    return UICollectionReusableView()
  }
  
  override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    searchBar.resignFirstResponder()
  }
  
  // MARK: - UI Update
  
  func didUpdateLibraryList(error: Error?) {
    activityIndicator.stopAnimating()
    activityIndicator.isHidden = true
    collectionView.isUserInteractionEnabled = true
    if let error = error {
      let alert = NYPLAlertUtils.alert(title: "LibraryListUpdateFailed", error: error as NSError)
      present(alert, animated: true, completion: nil)
      return
    }
    
    collectionView.reloadSections([NYPLLibraryFinderSection.newLibrary.rawValue])
  }
  
  // MARK: - UI Setup
  
  private func registerCollectionViewCell() {
    collectionView.register(NYPLLibraryFinderLibraryCell.self,
                            forCellWithReuseIdentifier: NYPLLibraryFinderLibraryCell.reuseId)
    collectionView.register(NYPLLibraryFinderSectionHeaderView.self,
                            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                            withReuseIdentifier: NYPLLibraryFinderSectionHeaderView.reuseId)
    collectionView.register(NYPLLibraryFinderSectionFooterView.self,
                            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                            withReuseIdentifier: NYPLLibraryFinderSectionFooterView.reuseId)
    collectionView.register(UICollectionReusableView.self,
                            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                            withReuseIdentifier: searchBar.reuseId)
  }
  
  private func setupCollectionViewUI() {
    collectionView.backgroundColor = NYPLConfiguration.backgroundColor()
    self.title = NSLocalizedString("Find a Library", comment: "Title for Library Finder")
    
    let contentInset = NYPLLibraryFinderConfiguration.collectionViewContentInset
    collectionView.contentInset = UIEdgeInsets(top: contentInset, left: contentInset, bottom: contentInset, right: contentInset)
    
    if let layout = self.collectionViewLayout as? UICollectionViewFlowLayout {
      let insets = contentInset * 2
      layout.estimatedItemSize = CGSize(width: collectionView.bounds.width - insets, height: 100)
    }
    
    // TODO: iOS-34 Only show background label when location service not allowed
    collectionView.backgroundView = backgroundLabel
  }
  
  private func setupActivityIndicator() {
    if #available(iOS 13.0, *) {
      activityIndicator.color = .label
    } else {
      activityIndicator.style = .gray
    }
    
    view.addSubview(activityIndicator)
    activityIndicator.autoCenterInSuperview()
    view.bringSubviewToFront(activityIndicator)
    activityIndicator.isHidden = true
  }
  
  let activityIndicator = UIActivityIndicatorView()
  
  lazy var searchBar : UISearchBar = {
    let searchBar = UISearchBar()
    searchBar.placeholder = NSLocalizedString("Location, library name or zip code", comment: "Placeholder text for search bar")
    searchBar.searchBarStyle = .minimal
    searchBar.delegate = self
    return searchBar
  }()
  
  lazy var backgroundLabel: UILabel = {
    let label = UILabel()
    label.numberOfLines = 0
    label.text = NSLocalizedString("You can search for your library by name, branch location, or your own location", comment: "Tips for searching in background")
    label.textAlignment = .center
    label.textColor = .lightGray
    return label
  }()
}

// MARK: - NYPLLibraryFinderDisplaying

extension NYPLLibraryFinderViewController: NYPLLibraryFinderDisplaying {
  func toggleLibrarySection(shouldShow: Bool) {
    isMyLibraryHidden = !isMyLibraryHidden
    UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
      self.collectionView.reloadSections([NYPLLibraryFinderSection.myLibrary.rawValue])
    }) { (_) in
      // Since the library cells are dynamic height due to it's content,
      // The starting position of "Add New Library" section could be off after the first section expanded.
      // That's why we need to invalidate the layout after expanding the first section
      self.collectionView.collectionViewLayout.invalidateLayout()
    }
  }
}

// MARK: - UISearchBarDelegate

extension NYPLLibraryFinderViewController: UISearchBarDelegate {
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    activityIndicator.isHidden = false
    activityIndicator.startAnimating()
    collectionView.isUserInteractionEnabled = false
    searchBar.resignFirstResponder()
    dataProvider.requestLibraryList(searchKeyword: searchBar.text) { [weak self] error in
      self?.didUpdateLibraryList(error: error)
    }
  }
}
