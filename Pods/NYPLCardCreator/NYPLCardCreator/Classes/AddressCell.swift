import UIKit

/// A subclass of `UITableViewCell` that displays an address within its content view.
final class AddressCell: UITableViewCell {
  
  let street1Label, street2Label, cityLabel, regionLabel, zipLabel: UILabel
  
  fileprivate var addressValue: Address?
  var address: Address? {
    get {
      return self.addressValue
    }
    set {
      self.addressValue = newValue
      self.street1Label.text = newValue?.street1
      self.street2Label.text = newValue?.street2
      self.cityLabel.text = newValue?.city
      if let region = newValue?.region {
        self.regionLabel.text = ", \(region) "
      }
      self.zipLabel.text = newValue?.zip
    }
  }
  
  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    self.street1Label = UILabel()
    self.street2Label = UILabel()
    self.cityLabel = UILabel()
    self.regionLabel = UILabel()
    self.zipLabel = UILabel()
    
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    
    self.contentView.addSubview(self.street1Label)
    self.street1Label.autoPinEdges(toSuperviewMarginsExcludingEdge: .bottom)
    
    self.contentView.addSubview(self.street2Label)
    self.street2Label.autoPinEdge(toSuperviewMargin: .left)
    self.street2Label.autoPinEdge(toSuperviewMargin: .right)
    self.street2Label.autoPinEdge(.top, to: .bottom, of: self.street1Label)
    
    self.contentView.addSubview(self.cityLabel)
    self.contentView.addSubview(self.regionLabel)
    self.contentView.addSubview(self.zipLabel)

    self.cityLabel.autoPinEdge(toSuperviewMargin: .left)
    self.cityLabel.autoPinEdge(.top, to: .bottom, of: self.street2Label)
    self.cityLabel.autoPinEdge(.right, to: .left, of: self.regionLabel)
    self.cityLabel.autoPinEdge(toSuperviewMargin: .bottom)
    
    self.regionLabel.autoPinEdge(.top, to: .bottom, of: self.street2Label)
    self.regionLabel.autoPinEdge(toSuperviewMargin: .bottom)
    
    self.zipLabel.autoPinEdge(.left, to: .right, of: self.regionLabel)
    self.zipLabel.autoPinEdge(.top, to: .bottom, of: self.street2Label)
    self.zipLabel.autoPinEdge(toSuperviewMargin: .bottom)
  }
  
  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
