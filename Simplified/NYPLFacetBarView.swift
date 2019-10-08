import Foundation

@objcMembers class NYPLFacetBarView : UIView {
  var entryPointView: NYPLEntryPointView;
  var facetView: NYPLFacetView;
  
  @available(*, unavailable)
  private override init(frame: CGRect) {
    self.entryPointView = NYPLEntryPointView()
    self.facetView = NYPLFacetView()
    
    super.init(frame: frame)
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  init(origin: CGPoint, width: CGFloat) {
    self.entryPointView = NYPLEntryPointView()
    self.facetView = NYPLFacetView()
    
    let borderHeight = 1.0 / UIScreen.main.scale;
    let toolbarHeight = CGFloat(40);
    
    super.init(frame: CGRect(x: origin.x, y: origin.y, width: width, height: borderHeight + toolbarHeight))
    
    var blur: UIVisualEffect;
    if #available(iOS 13, *) {
      blur = UIBlurEffect(style: .prominent);
    } else {
      blur = UIBlurEffect(style: .extraLight);
    }
    let bgBlur = UIVisualEffectView(effect: blur)

    addSubview(bgBlur)
    bgBlur.autoPinEdgesToSuperviewEdges()

    self.entryPointView.isHidden = true;
    self.facetView.isHidden = true;

    let bottomBorderView = UIView()
    bottomBorderView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.9)
    let topBorderView = UIView()
    topBorderView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.9)

    addSubview(self.facetView)
    addSubview(self.entryPointView)
    self.entryPointView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .bottom)
    self.facetView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .top)
    self.entryPointView.autoPinEdge(.bottom, to: .top, of: self.facetView)

    self.facetView.addSubview(bottomBorderView)
    bottomBorderView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .top)
    bottomBorderView.autoSetDimension(.height, toSize: borderHeight)
    self.facetView.addSubview(topBorderView)
    topBorderView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .bottom)
    topBorderView.autoSetDimension(.height, toSize:borderHeight)
  }
}
