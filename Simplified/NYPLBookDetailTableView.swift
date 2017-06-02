import Foundation
import PureLayout

@objc protocol BookDetailTableViewDelegate {
  func reportProblemTapped()
  func citationsTapped()
}


class NYPLBookDetailTableView: UITableView {
  
  override init(frame: CGRect, style: UITableViewStyle) {
    super.init(frame: frame, style: style)
    self.isScrollEnabled = false
    self.backgroundColor = UIColor.clear
    self.separatorStyle = .singleLine
    self.layoutMargins = UIEdgeInsetsMake(self.layoutMargins.top,
                                          self.layoutMargins.left+12,
                                          self.layoutMargins.bottom,
                                          self.layoutMargins.right+12)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override public var intrinsicContentSize: CGSize {
    get {
      layoutIfNeeded()
      return CGSize(width: UIViewNoIntrinsicMetric, height: contentSize.height)
    }
  }
}

private let sectionHeaderHeight: CGFloat = 40.0
private let laneCellHeight: CGFloat = 120.0
private let standardCellHeight: CGFloat = 44.0

class NYPLBookDetailTableViewDelegate: NSObject, UITableViewDataSource, UITableViewDelegate {
  
  enum BookDetailCellType: String {
    case groupedFeedLane = "Related Books"
    case reportAProblem = "Report a Problem"
    case citations = "Create Citation"
  }
  
  weak var viewDelegate: BookDetailTableViewDelegate?
  weak var tableView: UITableView?
  var book: NYPLBook
  
  var standardCells = [(UITableViewCell,BookDetailCellType)]()
  var laneCells = [NYPLCatalogLaneCell]()
  var laneFeeds = [NYPLCatalogLane]()
  
  init (_ tableView: UITableView, book: NYPLBook) {
    self.tableView = tableView
    self.book = book
  }
  
  func load() {
    if book.acquisition.report != nil {
      standardCells.append(createCell(type: .reportAProblem))
    }
    //GOOD Temporary Citations Example
    standardCells.append(createCell(type: .citations))
    refresh()
    
    NYPLOPDSFeed.withURL(self.book.relatedWorksURL) { (feed, errorDict) in
      DispatchQueue.main.async {
        if feed?.type == .acquisitionGrouped {
          let groupedFeed = NYPLCatalogGroupedFeed.init(opdsFeed: feed)
          self.createLaneCells(groupedFeed)
        } else {
          Log.error(#file, "Grouped feed expected")
        }
      }
    }
  }
  
  private func refresh() {
    self.tableView?.reloadData()
    self.tableView?.invalidateIntrinsicContentSize()
  }
  
  private func createLaneCells(_ groupedFeed: NYPLCatalogGroupedFeed?) {
    guard let feed = groupedFeed else { return }
    
    var books = [NYPLBook]()
    for lane in feed.lanes as! [NYPLCatalogLane] {
      books += lane.books as! [NYPLBook]
    }

    NYPLBookRegistry.shared().thumbnailImages(forBooks: Set(books.map{$0})) { (bookIdentifierToImages) in
      var index: UInt = 0
      for lane in feed.lanes as! [NYPLCatalogLane] {
        if let laneCell = NYPLCatalogLaneCell(laneIndex: index, books: lane.books,
                                              bookIdentifiersToImages: bookIdentifierToImages)
        {
          laneCell.delegate = self.viewDelegate as? NYPLCatalogLaneCellDelegate
          self.laneCells.append(laneCell)
          self.laneFeeds.append(lane)
          index += 1
          //GODO check and rid of redundant title lanes
        }
      }
      self.refresh()
    }
  }

  func createCell(type: BookDetailCellType) -> (UITableViewCell,BookDetailCellType) {
    let cell = UITableViewCell()
    cell.accessoryType = .disclosureIndicator
    cell.backgroundColor = UIColor.clear
    cell.textLabel?.font = UIFont.customFont(forTextStyle: .body)
    cell.textLabel?.text = type.rawValue
    return (cell,type)
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if (section < self.laneCells.count) {
      return 1
    } else {
      return self.standardCells.count
    }
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    if (self.laneCells.count == 0) {
      return 1
    } else {
      return 1 + self.laneCells.count
    }
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if (indexPath.section < self.laneCells.count) {
      return self.laneCells[indexPath.section]
    } else {
      return self.standardCells[indexPath.row].0
    }
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if (indexPath.section >= self.laneCells.count) {
      switch self.standardCells[indexPath.row].1 {
      case .reportAProblem:
        self.viewDelegate?.reportProblemTapped()
      case .groupedFeedLane:
        break
      case .citations:
        self.viewDelegate?.citationsTapped()
      }
    }
    tableView.deselectRow(at: indexPath, animated: true)
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if (indexPath.section < self.laneCells.count) {
      return laneCellHeight
    } else {
      return standardCellHeight
    }
  }
  
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    if (section >= self.laneCells.count) {
      return nil
    } else {
      return laneHeaderView(section)
    }
  }
  
  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    if (section >= self.laneCells.count) {
      return 0
    } else {
      return sectionHeaderHeight
    }
  }

  func laneHeaderView(_ section: Int) -> UIView? {
    let container = UIView()
    let headerButton = UIButton()
//    let moreButton = UIButton()
//    headerButton.addTarget(viewDelegate, action: #selector(viewDelegate.didSelectReportProblem(for:sender:)), for: .touchUpInside)
    headerButton.setTitle(laneFeeds[section].title, for: .normal)
    headerButton.setTitleColor(.black, for: .normal)
    headerButton.titleLabel?.font = UIFont.customBoldFont(forTextStyle: UIFontTextStyle.caption1)
    
//    moreButton.addTarget(viewDelegate, action: #selector(viewDelegate.didSelectRelatedWorks(for:sender:)), for: .touchUpInside)
//    moreButton.setTitle("More...", for: .normal)
//    moreButton.setTitleColor(.black, for: .normal)
//    moreButton.titleLabel?.font = UIFont.customFont(forTextStyle: UIFontTextStyle.caption1)
    
    container.addSubview(headerButton)
//    container.addSubview(moreButton)
    headerButton.autoAlignAxis(toSuperviewAxis: .horizontal)
    headerButton.autoPinEdge(toSuperviewEdge: .leading, withInset: 20)
//    moreButton.autoAlignAxis(toSuperviewAxis: .horizontal)
//    moreButton.autoPinEdge(toSuperviewMargin: .trailing)
    return container
  }
  
}
