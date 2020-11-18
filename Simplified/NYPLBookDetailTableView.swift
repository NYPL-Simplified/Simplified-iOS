import Foundation
import PureLayout

@objc protocol BookDetailTableViewDelegate {
  func reportProblemTapped()
  func moreBooksTapped(forLane: NYPLCatalogLane)
  func viewIssuesTapped()
}


final class NYPLBookDetailTableView: UITableView {
  
  override init(frame: CGRect, style: UITableView.Style) {
    super.init(frame: frame, style: style)
    self.isScrollEnabled = false
    self.backgroundColor = UIColor.clear
    self.separatorStyle = .singleLine
    self.layoutMargins = UIEdgeInsets.init(top: self.layoutMargins.top,
                                          left: self.layoutMargins.left+12,
                                          bottom: self.layoutMargins.bottom,
                                          right: self.layoutMargins.right+12)
    self.estimatedRowHeight = 0
    self.estimatedSectionHeaderHeight = 0
    self.estimatedSectionFooterHeight = 0
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override public var intrinsicContentSize: CGSize {
    get {
      layoutIfNeeded()
      return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
  }
}

private let sectionHeaderHeight: CGFloat = 40.0
private let sectionFooterHeight: CGFloat = 18.0
private let laneCellHeight: CGFloat = 120.0
private let standardCellHeight: CGFloat = 44.0

@objcMembers final class NYPLBookDetailTableViewDelegate: NSObject, UITableViewDataSource, UITableViewDelegate {
  
  enum BookDetailCellType: String {
    case groupedFeedDownloadPending = "Loading Related Books"
    case groupedFeedLane = "Related Books"
    case reportAProblem = "Report a Problem"
    case viewIssues = "View Issues"
  }
  
  class func createCell(type: BookDetailCellType) -> (UITableViewCell,BookDetailCellType) {
    let cell = UITableViewCell()
    cell.accessoryType = .disclosureIndicator
    cell.backgroundColor = UIColor.clear
    cell.textLabel?.font = UIFont.customFont(forTextStyle: .body)
    cell.textLabel?.text = NSLocalizedString(type.rawValue, comment: "")
    return (cell,type)
  }
  
  weak var viewDelegate: BookDetailTableViewDelegate?
  weak var laneCellDelegate: NYPLCatalogLaneCellDelegate?
  weak var tableView: UITableView?
  var book: NYPLBook
  
  var standardCells = [(UITableViewCell,BookDetailCellType)]()
  let viewIssueCell = createCell(type: BookDetailCellType.viewIssues)
  var catalogLaneCells = [NYPLCatalogLaneCell]()
  var catalogLanes = [NYPLCatalogLane]()
  
  init (_ tableView: UITableView, book: NYPLBook) {
    self.tableView = tableView
    self.book = book
  }
  
  func load() {
    NotificationCenter.default.addObserver(self, selector: #selector(self.updateFonts), name: UIContentSizeCategory.didChangeNotification, object: nil)
    
    if book.reportURL != nil {
      standardCells.append(NYPLBookDetailTableViewDelegate.createCell(type: .reportAProblem))
    }
    configureViewIssuesCell()
    refresh()
    
    guard let url = self.book.relatedWorksURL else {
      Log.error(#file, "No URL for Related Works")
      return
    }

    addPendingIndicator()
    NYPLOPDSFeed.withURL(url, shouldResetCache: false) { (feed, errorDict) in
      DispatchQueue.main.async {
        if feed?.type == .acquisitionGrouped {
          let groupedFeed = NYPLCatalogGroupedFeed.init(opdsFeed: feed)
          self.createLaneCells(groupedFeed)
        } else {
          self.removePendingIndicator()
          Log.error(#file, "Abandonding attempt to create related books lanes. OPDS Grouped Feed was expected.")
        }
      }
    }
  }
  
  private func refresh() {
    tableView?.reloadData()
    tableView?.invalidateIntrinsicContentSize()
  }

  fileprivate func addPendingIndicator() {
    standardCells.insert(self.createPendingActivityCell(), at:0)
    tableView?.reloadSections(IndexSet.init(integer: 0), with: .fade)
    refresh()
  }

  fileprivate func removePendingIndicator() {
    standardCells.removeFirst()
    refresh()
  }
  
  func updateFonts() {
    for tuple in standardCells {
      tuple.0.textLabel?.font = UIFont.customFont(forTextStyle: .body)
      tuple.0.textLabel?.text = tuple.1.rawValue
    }
  }

  private func createLaneCells(_ groupedFeed: NYPLCatalogGroupedFeed?) {
    guard let feed = groupedFeed else {
      removePendingIndicator()
      return
    }
    var books = [NYPLBook]()
    for lane in feed.lanes as! [NYPLCatalogLane] {
      books += lane.books as! [NYPLBook]
    }

    UIApplication.shared.isNetworkActivityIndicatorVisible = true
    NYPLBookRegistry.shared().thumbnailImages(forBooks: Set(books.map{$0})) { (bookIdentifierToImages) in
      UIApplication.shared.isNetworkActivityIndicatorVisible = false
      var index: UInt = 0
      for lane in feed.lanes as! [NYPLCatalogLane] {
        if let laneCell = NYPLCatalogLaneCell(laneIndex: index, books: lane.books,
                                              bookIdentifiersToImages: bookIdentifierToImages)
        {
          laneCell.delegate = self.laneCellDelegate
          self.catalogLaneCells.append(laneCell)
          self.catalogLanes.append(lane)
          index += 1
          self.checkAndRemoveRedundantTitles(lane, &index)
        }
      }
      self.removePendingIndicator()
    }
  }

  func createPendingActivityCell() -> (UITableViewCell,BookDetailCellType) {
    let cell = UITableViewCell()
    cell.backgroundColor = .clear
    let activityIndicator = UIActivityIndicatorView()
    if #available(iOS 13.0, *) {
      activityIndicator.color = .label
    } else {
      activityIndicator.style = .gray
    }
    cell.contentView.addSubview(activityIndicator)
    activityIndicator.autoCenterInSuperview()
    activityIndicator.startAnimating()
    return (cell, .groupedFeedDownloadPending)
  }
  
  func checkAndRemoveRedundantTitles(_ lane: NYPLCatalogLane, _ index: inout UInt) {
    if (lane.books.count == 1) {
      if (lane.books[0] as! NYPLBook).title == self.book.title {
        self.catalogLaneCells.removeLast()
        self.catalogLanes.removeLast()
        index -= 1
      }
    }
  }

  func moreBooksTapped(sender: UIButton) {
    self.viewDelegate?.moreBooksTapped(forLane: self.catalogLanes[sender.tag])
  }
  
  @objc func configureViewIssuesCell() {
    // It seems tuple equality operator can't handle optionals. So we do the long check.
    let lastStandardCell = self.standardCells.last
    let lastCellIsViewIssue = (lastStandardCell != nil) && (lastStandardCell! == self.viewIssueCell)
    
    // Visibility logic
    if NYPLProblemDocumentCacheManager.shared.getLastCachedDoc(self.book.identifier) == nil {
      if lastCellIsViewIssue {
        self.standardCells.removeLast()
      }
    } else {
      if !lastCellIsViewIssue {
        self.standardCells.append(self.viewIssueCell)
      }
    }
  }

  // MARK: - UITableView Delegate Methods

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let rowCount: Int
    if (section < self.catalogLaneCells.count) {
      rowCount = 1
    } else {
      rowCount = self.standardCells.count
    }
    return rowCount
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    let sectionCount: Int
    if (self.catalogLaneCells.count == 0) {
      sectionCount = 1
    } else {
      sectionCount =  1 + self.catalogLaneCells.count
    }
    return sectionCount
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if (indexPath.section < self.catalogLaneCells.count) {
      return self.catalogLaneCells[indexPath.section]
    } else {
      return self.standardCells[indexPath.row].0
    }
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if (indexPath.section >= self.catalogLaneCells.count) {
      switch self.standardCells[indexPath.row].1 {
      case .reportAProblem:
        self.viewDelegate?.reportProblemTapped()
      case .viewIssues:
        self.viewDelegate?.viewIssuesTapped()
      default:
        break
      }
    }
    tableView.deselectRow(at: indexPath, animated: true)
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    let height: CGFloat
    if (indexPath.section < self.catalogLaneCells.count) {
      height = laneCellHeight
    } else {
      height = standardCellHeight
    }
    return height
  }
  
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    if (section >= self.catalogLaneCells.count) {
      return nil
    } else {
      return laneHeaderView(section)
    }
  }
  
  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    if (section >= self.catalogLaneCells.count) {
      return 0
    } else {
      return sectionHeaderHeight
    }
  }
  
  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    if (section >= self.catalogLaneCells.count) {
      return nil
    } else {
      return laneFooterView()
    }
  }
  
  func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    if (section >= self.catalogLaneCells.count) {
      return 0
    } else {
      return sectionFooterHeight
    }
  }

  func laneHeaderView(_ section: Int) -> UIView? {
    let container = UIView()
    let headerButton = UIButton()
    let moreButton = UIButton()

    headerButton.setTitle(catalogLanes[section].title, for: .normal)
    if #available(iOS 13.0, *) {
      headerButton.setTitleColor(.label, for: .normal)
    } else {
      headerButton.setTitleColor(.black, for: .normal)
    }
    headerButton.titleLabel?.font = UIFont.customBoldFont(forTextStyle: UIFont.TextStyle.caption1)
    headerButton.titleLabel?.textAlignment = NSTextAlignment.left
    headerButton.titleLabel?.autoPinEdge(toSuperviewEdge: .left)
    headerButton.titleLabel?.lineBreakMode = NSLineBreakMode.byTruncatingTail;

    moreButton.addTarget(self, action: #selector(moreBooksTapped(sender:)), for: .touchUpInside)
    moreButton.tag = section
    moreButton.setTitle(NSLocalizedString("More...", comment: ""), for: .normal)
    if #available(iOS 13.0, *) {
      moreButton.setTitleColor(.label, for: .normal)
    } else {
      moreButton.setTitleColor(.black, for: .normal)
    }
    moreButton.titleLabel?.font = UIFont.customFont(forTextStyle: UIFont.TextStyle.caption1)
    moreButton.titleLabel?.textAlignment = NSTextAlignment.right
    moreButton.titleLabel?.autoPinEdge(toSuperviewEdge: .right)
    
    container.addSubview(headerButton)
    container.addSubview(moreButton)
    headerButton.autoAlignAxis(toSuperviewAxis: .horizontal)
    headerButton.autoPinEdge(toSuperviewEdge: .leading, withInset: 20)
    headerButton.autoPinEdge(.trailing, to: .leading, of: moreButton, withOffset: -20)
    moreButton.autoAlignAxis(toSuperviewAxis: .horizontal)
    moreButton.autoPinEdge(toSuperviewMargin: .trailing)
    return container
  }
  
  func laneFooterView() -> UIView? {
    let container = UIView()
    let separator = UIView()
    separator.backgroundColor = UIColor.lightGray
    container.addSubview(separator)
    separator.autoSetDimension(.height, toSize: CGFloat(1.0) / UIScreen.main.scale)
    separator.autoPinEdge(toSuperviewEdge: .trailing)
    separator.autoPinEdge(toSuperviewEdge: .bottom)
    separator.autoPinEdge(toSuperviewEdge: .leading)
    
    return container
  }
}
