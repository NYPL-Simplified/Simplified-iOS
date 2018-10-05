import UIKit

@objc protocol NYPLEntryPointControlDelegate {
  func didSelect(entryPointFacet: NYPLCatalogFacet)
}

class NYPLEntryPointView: UIView {

  private static let SegmentedControlMaxWidth: CGFloat = 300.0

  private let segmentedControl: UISegmentedControl
  private let facets: [NYPLCatalogFacet]
  private weak var delegate: NYPLEntryPointControlDelegate?

  /// Create a view to handle OPDS Entry Points.
  /// Will return nil if there are not enough valid facets.
  ///
  /// - Parameters:
  ///   - facets: the given OPDS facets
  ///   - delegate: delegate to handle segmented control selection
  @objc required init?(facets: [NYPLCatalogFacet], delegate: NYPLEntryPointControlDelegate) {
    let titles = NYPLEntryPointView.titlesFrom(facets: facets)
    if titles.count < 2 {
      NSLog("Invalid parameters for entry point view")
      return nil
    }
    self.segmentedControl = UISegmentedControl.init(items: titles)
    self.facets = facets
    self.delegate = delegate
    super.init(frame: .zero)
    setupSubviews()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupSubviews() {
    for index in 0..<facets.count {
      if (facets[index].active) {
        segmentedControl.selectedSegmentIndex = index
      }
    }
    segmentedControl.addTarget(self, action: #selector(didSelect(control:)), for: .valueChanged)

    self.addSubview(segmentedControl)
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

  }

  @objc private func didSelect(control: UISegmentedControl) {
    if control.selectedSegmentIndex >= facets.count {
      fatalError("InternalInconsistencyError")
    }
    delegate?.didSelect(entryPointFacet: facets[control.selectedSegmentIndex])
  }

  private class func titlesFrom(facets: [NYPLCatalogFacet]) -> [String] {
    var titles = [String]()
    for facet in facets {
      if let title = facet.title {
        titles.append(title)
      }
    }
    return titles
  }
}
