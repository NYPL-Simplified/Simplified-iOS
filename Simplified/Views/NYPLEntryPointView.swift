import UIKit

@objc protocol NYPLEntryPointViewDelegate {
  func entryPointViewDidSelect(entryPointFacet: NYPLCatalogFacet)
}

@objc protocol NYPLEntryPointViewDataSource {
  func facetsForEntryPointView() -> [NYPLCatalogFacet]
}

final class NYPLEntryPointView: UIView {

  private static let SegmentedControlMaxWidth: CGFloat = 300.0
  private static let EntryPointViewHeight: CGFloat = 54.0

  private var facets: [NYPLCatalogFacet]!
  @objc weak var dataSource: NYPLEntryPointViewDataSource? {
    didSet {
      if (dataSource != nil && delegate != nil) {
        reloadData()
      }
    }
  }
  @objc weak var delegate: NYPLEntryPointViewDelegate? {
    didSet {
      if (dataSource != nil && delegate != nil) {
        reloadData()
      }
    }
  }

  @objc func reloadData()
  {
    isHidden = true
    
    for subview in subviews {
      subview.removeFromSuperview()
    }

    facets = dataSource?.facetsForEntryPointView() ?? []
    let titles = NYPLEntryPointView.titlesFrom(facets: facets)
    if titles.count < 2 {
      autoSetDimension(.height, toSize: 0.0)
      return
    }

    let segmentedControl = UISegmentedControl(items: titles)
    setupSubviews(segmentedControl)
    isHidden = false;
  }

  private func setupSubviews(_ segmentedControl: UISegmentedControl)
  {
    for index in 0..<facets.count {
      if (facets[index].active) {
        segmentedControl.selectedSegmentIndex = index
      }
    }
    segmentedControl.addTarget(self, action: #selector(didSelect(control:)), for: .valueChanged)

    addSubview(segmentedControl)
    NSLayoutConstraint.autoSetPriority(.defaultHigh) {
      segmentedControl.autoSetDimension(.width, toSize: NYPLEntryPointView.SegmentedControlMaxWidth)
    }
    NSLayoutConstraint.autoSetPriority(.defaultLow) {
      segmentedControl.autoPinEdge(toSuperviewMargin: .leading)
      segmentedControl.autoPinEdge(toSuperviewMargin: .trailing)
    }
    segmentedControl.autoPinEdge(toSuperviewMargin: .leading, relation: .greaterThanOrEqual)
    segmentedControl.autoPinEdge(toSuperviewMargin: .trailing, relation: .greaterThanOrEqual)
    segmentedControl.autoCenterInSuperview()

    autoSetDimension(.height, toSize: NYPLEntryPointView.EntryPointViewHeight)
  }

  @objc private func didSelect(control: UISegmentedControl)
  {
    let facets = dataSource!.facetsForEntryPointView()
    if control.selectedSegmentIndex >= facets.count {
      fatalError("InternalInconsistencyError")
    }
    delegate!.entryPointViewDidSelect(entryPointFacet: facets[control.selectedSegmentIndex])
  }

  private class func titlesFrom(facets: [NYPLCatalogFacet]) -> [String]
  {
    var titles = [String]()
    for facet in facets {
      if let title = facet.title {
        titles.append(title)
      }
    }
    return titles
  }
}
